class AgreementsController < ApplicationController
  def new
    @agreement = Agreement.new
    @agreement.budgetary_responsibilities = [{}]
    @agreement.objectives = [{}]

    set_implicit_parameter
  end

  def create
    @agreement = Agreement.new(agreement_params)
    set_implicit_parameter

    if @agreement.save
      redirect_to '/', notice: 'Agreement was successfully created.'
    else
      render :new
    end
  end

  def edit
    @agreement = Agreement.find(params[:id])
  end

  def index
    @agreements = Agreement.all
  end

private
  def set_implicit_parameter
    @agreement.jobholder = current_user
  end

  def agreement_params
    params[:agreement].permit(:manager_email, :number_of_staff, :staff_engagement_score,
      budgetary_responsibilities: [:budget_type, :budget_value, :description],
      objectives: [:objective_type, :description, :deliverable, :measures])
  end
end
