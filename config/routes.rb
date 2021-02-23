Rails.application.routes.draw do
  root 'static_pages#top'
  get '/signup', to: 'users#new'

  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users do
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month'
      get 'confirmation_show'
    end
    resources :attendances, only: :update do
      member do
        get 'edit_overwork_request' # 残業申請用に追加。
        patch 'update_overwork_request' # 残業申請用に追加。
      end
      collection do
        get 'edit_overwork_notice' # 残業申請のお知らせ用に追加。
        patch 'update_overwork_notice' # 残業申請のお知らせ用に追加。
        get 'edit_change_notice' # 勤怠変更申請のお知らせ用に追加。
        patch 'update_change_notice' # 勤怠変更申請のお知らせ用に追加。
        get 'csv_output' # CSV出力用に追加。
        # get 'attendance_log' # 勤怠修正ログ取得用に追加。
        # post 'attendance_log' # 勤怠修正ログ取得用に追加。
      end
    end
  end
end