require 'csv'

CSV.generate do |csv|
  column_names = %w(日付 曜日 出社時間 退社時間)
  csv << column_names
  @attendances.each do |a|
    column_values = [
      a.worked_on.strftime("%-m/%-d"),
      $days_of_the_week[a.worked_on.wday],
      if a.started_at.present? 
        a.started_at.strftime("%H:%M")
      else
        ""
      end,
      if a.finished_at.present?
        a.finished_at.strftime("%H:%M")
      else
        ""
      end
    ]
    csv << column_values
  end
end