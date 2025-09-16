# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::Billing::PurchasesController < Api::V1::ApplicationController
    account_load_and_authorize_resource :purchase, through: :team, through_association: :billing_purchases

    # GET /api/v1/teams/:team_id/billing/purchases
    def index
    end

    # GET /api/v1/billing/purchases/:id
    def show
    end

    # POST /api/v1/teams/:team_id/billing/purchases
    def create
      if @purchase.save
        render :show, status: :created, location: [:api, :v1, @purchase]
      else
        render json: @purchase.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/billing/purchases/:id
    def update
      if @purchase.update(purchase_params)
        render :show
      else
        render json: @purchase.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/billing/purchases/:id
    def destroy
      @purchase.destroy
    end

    private

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def purchase_params
        strong_params = params.require(:billing_purchase).permit(
          *permitted_fields,
          :user_id,
          :access_pass_id,
          :amount_cents,
          :stripe_charge_id,
          :stripe_payment_intent_id,
          :status,
          # 🚅 super scaffolding will insert new fields above this line.
          *permitted_arrays,
          # 🚅 super scaffolding will insert new arrays above this line.
        )

        process_params(strong_params)

        strong_params
      end
    end

    include StrongParameters
  end
else
  class Api::V1::Billing::PurchasesController
  end
end
