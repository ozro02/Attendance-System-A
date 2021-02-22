class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month, :update_overwork_notice]
  before_action :set_user_2, only: [:csv_output, :attendance_log]
  before_action :set_one_month, only: [:edit_one_month, :csv_output]

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end
  
  def csv_output
    respond_to do |format|
      format.html
      format.csv do
        send_data render_to_string, filename: "#{@first_day.year}年#{@first_day.month}月の勤怠表.csv", type: :csv
      end
    end
  end
  
  def attendance_log
    @superior = User.where(superior: true).where.not(id: current_user.id)
    @attendances = @user.attendances.where(judgement: "承認", confirmation: @superior.id)
  end

  def edit_one_month
  end

  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.update_attributes!(item)
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  def edit_overwork_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
    @superior = User.where(superior: true).where.not(id: current_user.id)
  end
  
  def update_overwork_request
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
    if params[:attendance][:scheduled_end_time].blank? || params[:attendance][:business_process].blank? || params[:attendance][:confirmation].blank?
      flash[:danger] = "必須項目が空欄です。"
    else @attendance.update_attributes(overwork_params)
      flash[:success] = "残業を申請しました。"
    end
    redirect_to @user 
  end
  
  def edit_overwork_notice
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(request: "残業申請中", confirmation: @user.id).order(:user_id).group_by(&:user_id)
  end
  
  def update_overwork_notice
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(request: "残業申請中", confirmation: @user.id).order(:user_id).group_by(&:user_id)
    overwork_approval_params.each do |id, item|
      attendance = Attendance.find(id)
    # # if params[:attendance][:change] == true && params[:attendance][:judge] == "承認"
    #   @attendance.update_attributes(overwork_approval_params)
    #   flash[:success] = "残業申請を承認しました。"
    # elsif params[:attendance][:change] == true && params[:attendance][:judge] == "否認"
    #   @attendance.update_attributes(overwork_approval_params)
    #   flash[:success] = "残業申請を否認しました。"
    # elsif params[:attendance][:change] == true && params[:attendance][:judge] == "なし"
    #   @attendance.update_attributes(overwork_approval_params)
    #   flash[:success] = "残業申請を取り消しました。"
    # else
    #   flash[:danger] = "変更欄にチェックが必要です。"
    # end
    # redirect_to @user 
      # if params[:user][:attendances][:change] == true
        attendance.update_attributes(item)
        flash[:success] = "残業申請情報を変更しました。"
      # else
      #   flash[:danger] = "変更欄にチェックが必要です。"
      # end
    end
    redirect_to @user
  end
  
  private

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :next_day, :note])[:attendances]
    end
    
    # 残業申請を扱います。
    def overwork_params
      params.require(:attendance).permit(:scheduled_end_time, :next_day, :business_process, :confirmation, :request)
    end
    
     # 残業申請承認を扱います。
    def overwork_approval_params
      params.require(:user).permit(attendances: [:judgement, :change])[:attendances]
    end

    # beforeフィルター

    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
    
    def set_user_2
      @user = User.find(params[:user_id])
    end
end