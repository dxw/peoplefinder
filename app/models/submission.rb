class Submission < Review
  before_save :update_status
  attr_accessor :submitted

private

  def update_status
    self.status = submitted ? 'submitted' : 'started'
  end
end
