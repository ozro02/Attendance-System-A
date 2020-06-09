# coding: utf-8

User.create!(name: "Sample User",
             email: "sample@email.com",
             password: "password",
             password_confirmation: "password",
             admin: true)
             
User.create!(name: "上長A",
             email: "sample-1@email.com",
             password: "password",
             password_confirmation: "password",
             admin: false)      
             
User.create!(name: "上長B",
             email: "sample-2@email.com",
             password: "password",
             password_confirmation: "password",
             admin: false)                   

60.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+3}@email.com"
  password = "password"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password)
end