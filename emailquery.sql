-- Create a Database Mail profile  
EXECUTE msdb.dbo.sysmail_add_profile_sp  
    @profile_name = 'Notifications',  
    @description = 'Profile used for sending outgoing notifications using Gmail.' ;  
GO
-- Grant access to the profile to the DBMailUsers role  
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp  
    @profile_name = 'Notifications',  
    @principal_name = 'public',  
    @is_default = 1 ;
GO
-- Create a Database Mail account  
EXECUTE msdb.dbo.sysmail_add_account_sp  
    @account_name = 'Gmail',  
    @description = 'Mail account for sending outgoing notifications.',  
    @email_address = 'email@gmail.com',  
    @display_name = 'Automated Mailer',  
    @mailserver_name = 'smtp.gmail.com',
    @port = 587,
    @enable_ssl = 1,
    @username = 'email@gmail.com',
    @password = 'gmailapppassword' ;  
GO
-- Add the account to the profile  
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp  
    @profile_name = 'Notifications',  
    @account_name = 'Gmail',  
    @sequence_number =1 ;  
GO