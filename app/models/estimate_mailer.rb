class EstimateMailer < Mailer
  def exceeding_estimate_mail(user, issue)
    @issue = issue
    mail to: user.mail, subject: "Превышена оценка трудозатрат! ##{@issue.id}"
  end
end
