class Myspot::DonationAmountsController < ApplicationController

  before_filter :login_required, :except => [:show]
  helper_method :unpaid_donations, :unpaid_credits, :spotus_donation

  def show
    if params[:spotus_lite]
      redirect_to :action => 'spotus_lite'
    else
      redirect_to :action => 'edit'
    end
  end

  def edit
  end

  def spotus_lite
    render :layout=>"lite"
  end

  def update
    
    donation_amounts = params[:donation_amounts]
    credit_pitch_amounts = params[:credit_pitch_amounts]
    available_credits = current_user.total_credits
    
    #merge the amounts arrays
    amounts = {}
    amounts.merge!(donation_amounts) if donation_amounts
    amounts.merge!(credit_pitch_amounts) if credit_pitch_amounts

    @donations = []
    @credit_pitches = []
    
    amounts.each do |key, amount|
      donation_amount = amount["amount"]
      if available_credits>0
        if donation_amount.to_f>available_credits
          donation = Donation.update(key, amount)
          credit = Credit.create(:user => current_user, :description => "Applied to Pitches (#{key})",
                          :amount => (0 - donation_amount.to_f))
          donation.credit_id = credit.id
          donation.save
          @donations << donation
          available_credits=0
        else
          @credit_pitches << Donation.update(key, amount)
          available_credits -= donation_amount.to_f
        end
      else
        @donations << Donation.update(key, amount)
      end
    end
    
    update_balance_cookie
    
    if params[:submit] == "update"
      redirect_to :back
    else
      current_user.apply_credit_pitches?(@credit_pitches) if @credit_pitches && !@credit_pitches.empty?
      if spotus_donation     # todo: make sure we can pay the spotus donation in credits
        spotus_donation.update_attribute(:amount, params[:spotus_donation_amount])
        if available_credits>0
          if spotus_donation.amount.to_f>available_credits
            credit = Credit.create(:user => current_user, :description => "Donated to SpotUs",
                            :amount => (0 - available_credits.to_f))
            spotus_donation.credit_id = credit.id
            spotus_donation.save
            available_credits = 0
          else
            credit = Credit.create(:user => current_user, :description => "Donated to SpotUs",
                            :amount => (0 - spotus_donation.amount))
            spotus_donation.credit_id = credit.id
            spotus_donation.save
          end
        end
      end
      if (@donations && !@donations.empty? && @donations.all?{|d| d.valid? }) || (spotus_donation && spotus_donation.unpaid?)
        redirect_to new_myspot_purchase_path
      else
        if !@credit_pitches || @credit_pitches.empty?
          redirect_to cookies[:spotus_lite] ? "/lite/#{cookies[:spotus_lite]}" : myspot_donations_path
        else
          redirect_to cookies[:spotus_lite] ? "/lite/#{cookies[:spotus_lite]}" : pitch_url(@credit_pitches.first.pitch)
        end
      end
    end
  end

  protected

  def unpaid_donations
    @unpaid_donations ||= current_user.donations.unpaid
  end
  
  def unpaid_credits
    @unpaid_credits ||= current_user.credit_pitches.unpaid
  end

  def spotus_donation
    @spotus_donation ||= current_user.current_spotus_donation
  end

end

                     