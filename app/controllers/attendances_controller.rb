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
  
  # def attendance_log
  #   @superior = User.where(superior: true).where.not(id: current_user.id)
  #   @attendances = @user.attendances.where(judgement: "承認", confirmation: @superior)
  # end

  def edit_one_month
    @superior = User.where(superior: true).where.not(id: current_user.id)
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
  
  # 残業申請モーダル
  def edit_overwork_request 
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
    @superior = User.where(superior: true).where.not(id: current_user.id)
  end
  
  # 残業申請の更新処理
  def update_overwork_request 
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find(params[:id])
    # if overwork_params_updated_invalid?
      if params[:attendance][:confirmation].blank?
        flash[:danger] = "上長が選択されていません。"
        redirect_to @user
      else @attendance.update_attributes(overwork_params)
        flash[:success] = "残業を申請しました。"
        redirect_to @user
      end
    # else
      if params[:attendance][:scheduled_end_time] << @user.designated_work_end_time &&
          params[:attendance][:next_day] == "false"
        flash[:danger] = "指定勤務終了時間より早い終了予定時間は無効です。"
        redirect_to @user
      else
        flash[:success] = "申請情報に不正な入力があるため、残業申請できませんでした。"
        redirect_to @user
      end
    # end
  end
  
  # 残業申請お知らせのモーダル
  def edit_overwork_notice 
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(request: "申請中", confirmation: @user.id).order(:user_id).group_by(&:user_id)
  end
  
  # 残業申請お知らせの更新
  def update_overwork_notice 
    @user = User.find(params[:user_id])
    ActiveRecord::Base.transaction do 
      overwork_approval_params.each do |id, item|
        if item[:change] == "true"  
          attendance = Attendance.find(id)
          attendance.update_attributes!(item)
        end
      end
      flash[:success] = "残業申請情報を変更しました。"
      redirect_to @user and return
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to @user and return
  end
  
  # 勤怠編集のお知らせモーダル
  def edit_change_notice
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(change_request: "申請中", confirmation: @user.id).order(:user_id).group_by(&:user_id)
  end
  
  # 勤怠編集お知らせモーダルの更新
  def update_change_notice 
    @user = User.find(params[:user_id])
  end
  
  private

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :next_day, :note, :confirmation, :change_request])[:attendances]
    end
    
    # 残業申請を扱います。
    def overwork_params
      params.require(:attendance).permit(:scheduled_end_time, :next_day, :business_process, :confirmation, :request)
    end
    
     # 残業申請承認を扱います。
    def overwork_approval_params
      params.require(:user).permit(attendances: [:request, :change])[:attendances]
    end
    
    # 勤怠編集申請承認を扱います。
    # def attendances_approval_params
    #   params.require(:user).permit(attendances: [:change_request, :change])[:attendances]
    # end

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