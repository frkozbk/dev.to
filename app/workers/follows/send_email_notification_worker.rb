module Follows
  class SendEmailNotificationWorker
    include Sidekiq::Worker
    sidekiq_options queue: :mailers, retry: 10

    def perform(follow_id, mailer = NotifyMailer.name)
      follow = Follow.find_by(id: follow_id, followable_type: "User")
      return unless follow&.followable.present? && follow.followable.receives_follower_email_notifications?

      return if follow.follower.score < 25 # Restrict new follower emails to more active/established accounts

      return if EmailMessage.where(user_id: follow.followable_id).
        where("sent_at > ?", rand(15..35).hours.ago).
        where("subject LIKE ?", "%#{NotifyMailer::SUBJECTS[:new_follower_email]}").exists?

      mailer.constantize.new_follower_email(follow).deliver
    end
  end
end
