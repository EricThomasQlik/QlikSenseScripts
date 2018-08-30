#------------------------------------------------------------------------------------------------------------------------------
#
# Script Name: fix_monitor_apps.ps1
# Description: Reimports Monitoring Apps, recreates Data connections, switches data connections to use certificate auth
# Dependancies: Script most be ran from Central Node as the Qlik Sense Service Account
# 
#   Version    Date        Author         Change Notes
#   0.1        2018-08-30  Eric Thomas    Initial Version     
#
#   Notes: Not ready for June 2018 release as it doesn't handle the new Data connections
#
#------------------------------------------------------------------------------------------------------------------------------

#Prepare Connection information
#--------------------------------------
#Build Header
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Qlik-XrfKey",'NzU0NTIwMDAwNTIy')
$headers.Add("X-Qlik-User",'UserDirectory=internal; UserId=sa_api')

#Obtain Certficate
$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where {$_.Subject -like '*QlikClient*'}
#$thumbprint = Get-ChildItem -Path cert:\CurrentUser\my | Where {$_.Subject -like '*QlikClient*'}|Select Thumbprint
#$thumbprint = $thumbprint.Thumbprint

#Build FQDN
# Gets the configured hostname from the host.cfg file
$Data = Get-Content C:\ProgramData\Qlik\Sense\Host.cfg
# Convert the base64 encoded install name for Sense to UTF data
$FQDN = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($Data)))

#Handle TLS 1.2 only environments
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

#Get Password to be used with Certificate
$response = Read-host "Please enter a password that will be used for Client Certificate Authentication" -AsSecureString
$passwordCert = New-Object System.Net.NetworkCredential("Blank",$response)

#Export the Certificate
#--------------------------------------
$certBody = '{  
   "MachineNames":[  
      "'+$($FQDN)+'"
   ],
   "certificatePassword":"'+$($passwordCert.Password)+'",
   "includeSecretsKey":true,
   "exportFormat":"Windows"
}'

Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/CertificateDistribution/exportcertificates?xrfkey=NzU0NTIwMDAwNTIy" -Method Post -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $certBody

#Move the Certifcate for the REST Connector
#--------------------------------------
Move-Item -Path C:\ProgramData\Qlik\Sense\Repository\"Exported Certificates"\$($FQDN) -Destination C:\ProgramData\Qlik\Sense\Engine\Certificates


#Rename Data Connections
#--------------------------------------
#
#Really should try to loop through this as improvement
#

#Monitor_apps_rest_app
#---------------------------
$RESTapp = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_app')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 

#Filter out ID value
$RESTappID = $RESTapp.id

#GET the DataConnection JSON
$RESTappDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert

#Convert Response to JSON
$RESTappDC = $RESTappDC | ConvertTo-Json

#Modify App Name
$RESTappDC = $RESTappDC -replace "monitor_apps_REST_app", "monitor_apps_REST_app-old"

Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTappDC

#
#Repeat Through all Monitoring app Data Connections
#
#Monitor_apps_rest_appobject
#---------------------------
$RESTappObject = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_appobject')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTappObjectID = $RESTappObject.id
$RESTappObjectDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappObjectID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTappObjectDC = $RESTappObjectDC | ConvertTo-Json
$RESTappObjectDC = $RESTappObjectDC -replace "monitor_apps_REST_appobject", "monitor_apps_REST_appobject-old"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappObjectID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTappObjectDC
#Monitor_apps_rest_event
#---------------------------
$RESTevent = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_event')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTeventID = $RESTevent.id
$RESTeventDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTeventID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTeventDC = $RESTeventDC | ConvertTo-Json
$RESTeventDC = $RESTeventDC -replace "monitor_apps_REST_event", "monitor_apps_REST_event-old"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTeventID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTeventDC
#Monitor_apps_rest_license_access
#---------------------------
$RESTLicenseAccess = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_access')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseAccessID = $RESTLicenseAccess.id
$RESTLicenseAccessDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAccessID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseAccessDC = $RESTLicenseAccessDC | ConvertTo-Json
$RESTLicenseAccessDC = $RESTLicenseAccessDC -replace "monitor_apps_REST_license_access", "monitor_apps_REST_license_access-old"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAccessID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseAccessDC
#Monitor_apps_rest_license_login
#---------------------------
$RESTLicenseLogin = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_login')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseLoginID = $RESTLicenseLogin.id
$RESTLicenseLoginDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseLoginID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseLoginDC = $RESTLicenseLoginDC | ConvertTo-Json
$RESTLicenseLoginDC = $RESTLicenseLoginDC -replace "monitor_apps_REST_license_login", "monitor_apps_REST_license_login-old"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseLoginID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseLoginDC
#Monitor_apps_rest_license_user
#---------------------------
$RESTLicenseUser = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_user')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseUserID = $RESTLicenseUser.id
$RESTLicenseUserDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseUserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseUserDC = $RESTLicenseUserDC | ConvertTo-Json
$RESTLicenseUserDC = $RESTLicenseUserDC -replace "monitor_apps_REST_license_user", "monitor_apps_REST_license_user-old"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseUserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseUserDC
#Monitor_apps_rest_task
#---------------------------
$RESTtask = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_task')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTtaskID = $RESTtask.id
$RESTtaskDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTtaskID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTtaskDC = $RESTtaskDC | ConvertTo-Json
$RESTtaskDC = $RESTtaskDC -replace "monitor_apps_REST_task", "monitor_apps_REST_task-old"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTtaskID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTtaskDC
#Monitor_apps_rest_task
#---------------------------
$RESTuser = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_user')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTuserID = $RESTuser.id
$RESTuserDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTuserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTuserDC = $RESTuserDC | ConvertTo-Json
$RESTuserDC = $RESTuserDC -replace "monitor_apps_REST_user", "monitor_apps_REST_user-old"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTuserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTuserDC
#--------------------------------------


#Upload Operations Monitor
#--------------------------------------
#Build File Path
$fileLocation = $env:ProgramData+"\Qlik\Sense\Repository\DefaultApps\"+"Operations Monitor.qvf"

#Read Data
$FileContent = [IO.File]::ReadAllBytes($fileLocation)

#Perform Upload
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/app/upload?keepData=true&name=Operations+Monitor-New&xrfkey=NzU0NTIwMDAwNTIy" -Method Post -Headers $headers -ContentType 'application/vnd.qlik.sense.app' -Certificate $cert -Body $FileContent

#Upload License Monitor
#--------------------------------------
#Build File Path
$fileLocation = $env:ProgramData+"\Qlik\Sense\Repository\DefaultApps\"+"License Monitor.qvf"

#Read Data
$FileContent = [IO.File]::ReadAllBytes($fileLocation)

#Perform Upload
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/app/upload?keepData=true&name=License+Monitor-New&xrfkey=NzU0NTIwMDAwNTIy" -Method Post -Headers $headers -ContentType 'application/vnd.qlik.sense.app' -Certificate $cert -Body $FileContent

#Swap Data Connections to Cert Auth
#--------------------------------------

#Monitor_apps_rest_app
#---------------------------
$RESTapp = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_app')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 

#Filter out ID value
$RESTappID = $RESTapp.id

#GET the DataConnection JSON
$RESTappDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert

#Convert Response to JSON
$RESTappDC = $RESTappDC | ConvertTo-Json

#Switch Data Connection to Cert Auth
$RESTappDC = $RESTappDC -replace "url=https://localhost", "url=https://$($FQDN):4242"
$RESTappDC = $RESTappDC -replace "method=GET;", "method=GET;sendExpect100Continue=true;"
$RESTappDC = $RESTappDC -replace "useCertificate=No;certificateStoreLocation=CurrentUser;", "useCertificate=FromFile;certificateStoreLocation=LocalMachine;"
$RESTappDC = $RESTappDC -replace "authSchema=ntlm", "authSchema=anonymous"
$RESTappDC = $RESTappDC -replace "certificateStoreName=My;", "certificateStoreName=My;certificateFilePath=$($FQDN)\\client.pfx;"
$RESTappDC = $RESTappDC -replace "queryHeaders=X-Qlik-XrfKey%20000000000000000%1User-Agent%2Windows", "queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api"
$RESTappDC = $RESTappDC -replace "%%password%2Qlik123!%1", "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"

Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTappDC

#
#Repeat Through all Monitoring app Data Connections
#
#Monitor_apps_rest_appobject
#---------------------------
$RESTappObject = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_appobject')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTappObjectID = $RESTappObject.id
$RESTappObjectDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappObjectID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTappObjectDC = $RESTappObjectDC | ConvertTo-Json
$RESTappObjectDC = $RESTappObjectDC -replace "url=https://localhost", "url=https://$($FQDN):4242"
$RESTappObjectDC = $RESTappObjectDC -replace "method=GET;", "method=GET;sendExpect100Continue=true;"
$RESTappObjectDC = $RESTappObjectDC -replace "useCertificate=No;certificateStoreLocation=CurrentUser;", "useCertificate=FromFile;certificateStoreLocation=LocalMachine;"
$RESTappObjectDC = $RESTappObjectDC -replace "authSchema=ntlm", "authSchema=anonymous"
$RESTappObjectDC = $RESTappObjectDC -replace "certificateStoreName=My;", "certificateStoreName=My;certificateFilePath=$($FQDN)\\client.pfx;"
$RESTappObjectDC = $RESTappObjectDC -replace "queryHeaders=X-Qlik-XrfKey%20000000000000000%1User-Agent%2Windows", "queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api"
$RESTappObjectDC = $RESTappObjectDC -replace "%%password%2Qlik123!%1", "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTappObjectID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTappObjectDC
#Monitor_apps_rest_event
#---------------------------
$RESTevent = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_event')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTeventID = $RESTevent.id
$RESTeventDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTeventID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTeventDC = $RESTeventDC | ConvertTo-Json
$RESTeventDC = $RESTeventDC -replace "url=https://localhost", "url=https://$($FQDN):4242"
$RESTeventDC = $RESTeventDC -replace "method=GET;", "method=GET;sendExpect100Continue=true;"
$RESTeventDC = $RESTeventDC -replace "useCertificate=No;certificateStoreLocation=CurrentUser;", "useCertificate=FromFile;certificateStoreLocation=LocalMachine;"
$RESTeventDC = $RESTeventDC -replace "authSchema=ntlm", "authSchema=anonymous"
$RESTeventDC = $RESTeventDC -replace "certificateStoreName=My;", "certificateStoreName=My;certificateFilePath=$($FQDN)\\client.pfx;"
$RESTeventDC = $RESTeventDC -replace "queryHeaders=X-Qlik-XrfKey%20000000000000000%1User-Agent%2Windows", "queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api"
$RESTeventDC = $RESTeventDC -replace "%%password%2Qlik123!%1", "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTeventID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTeventDC
#Monitor_apps_rest_license_access
#---------------------------
$RESTLicenseAccess = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_access')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseAccessID = $RESTLicenseAccess.id
$RESTLicenseAccessDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAccessID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseAccessDC = $RESTLicenseAccessDC | ConvertTo-Json
$RESTLicenseAccessDC = $RESTLicenseAccessDC -replace "url=https://localhost", "url=https://$($FQDN):4242"
$RESTLicenseAccessDC = $RESTLicenseAccessDC -replace "method=GET;", "method=GET;sendExpect100Continue=true;"
$RESTLicenseAccessDC = $RESTLicenseAccessDC -replace "useCertificate=No;certificateStoreLocation=CurrentUser;", "useCertificate=FromFile;certificateStoreLocation=LocalMachine;"
$RESTLicenseAccessDC = $RESTLicenseAccessDC -replace "authSchema=ntlm", "authSchema=anonymous"
$RESTLicenseAccessDC = $RESTLicenseAccessDC -replace "certificateStoreName=My;", "certificateStoreName=My;certificateFilePath=$($FQDN)\\client.pfx;"
$RESTLicenseAccessDC = $RESTLicenseAccessDC -replace "queryHeaders=X-Qlik-XrfKey%20000000000000000%1User-Agent%2Windows", "queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api"
$RESTLicenseAccessDC = $RESTLicenseAccessDC -replace "%%password%2Qlik123!%1", "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseAccessID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseAccessDC
#Monitor_apps_rest_license_login
#---------------------------
$RESTLicenseLogin = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_login')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseLoginID = $RESTLicenseLogin.id
$RESTLicenseLoginDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseLoginID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseLoginDC = $RESTLicenseLoginDC | ConvertTo-Json
$RESTLicenseLoginDC = $RESTLicenseLoginDC -replace "url=https://localhost", "url=https://$($FQDN):4242"
$RESTLicenseLoginDC = $RESTLicenseLoginDC -replace "method=GET;", "method=GET;sendExpect100Continue=true;"
$RESTLicenseLoginDC = $RESTLicenseLoginDC -replace "useCertificate=No;certificateStoreLocation=CurrentUser;", "useCertificate=FromFile;certificateStoreLocation=LocalMachine;"
$RESTLicenseLoginDC = $RESTLicenseLoginDC -replace "authSchema=ntlm", "authSchema=anonymous"
$RESTLicenseLoginDC = $RESTLicenseLoginDC -replace "certificateStoreName=My;", "certificateStoreName=My;certificateFilePath=$($FQDN)\\client.pfx;"
$RESTLicenseLoginDC = $RESTLicenseLoginDC -replace "queryHeaders=X-Qlik-XrfKey%20000000000000000%1User-Agent%2Windows", "queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api"
$RESTLicenseLoginDC = $RESTLicenseLoginDC -replace "%%password%2Qlik123!%1", "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseLoginID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseLoginDC
#Monitor_apps_rest_license_user
#---------------------------
$RESTLicenseUser = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_license_user')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTLicenseUserID = $RESTLicenseUser.id
$RESTLicenseUserDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseUserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTLicenseUserDC = $RESTLicenseUserDC | ConvertTo-Json
$RESTLicenseUserDC = $RESTLicenseUserDC -replace "url=https://localhost", "url=https://$($FQDN):4242"
$RESTLicenseUserDC = $RESTLicenseUserDC -replace "method=GET;", "method=GET;sendExpect100Continue=true;"
$RESTLicenseUserDC = $RESTLicenseUserDC -replace "useCertificate=No;certificateStoreLocation=CurrentUser;", "useCertificate=FromFile;certificateStoreLocation=LocalMachine;"
$RESTLicenseUserDC = $RESTLicenseUserDC -replace "authSchema=ntlm", "authSchema=anonymous"
$RESTLicenseUserDC = $RESTLicenseUserDC -replace "certificateStoreName=My;", "certificateStoreName=My;certificateFilePath=$($FQDN)\\client.pfx;"
$RESTLicenseUserDC = $RESTLicenseUserDC -replace "queryHeaders=X-Qlik-XrfKey%20000000000000000%1User-Agent%2Windows", "queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api"
$RESTLicenseUserDC = $RESTLicenseUserDC -replace "%%password%2Qlik123!%1", "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTLicenseUserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTLicenseUserDC
#Monitor_apps_rest_task
#---------------------------
$RESTtask = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_task')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTtaskID = $RESTtask.id
$RESTtaskDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTtaskID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTtaskDC = $RESTtaskDC | ConvertTo-Json
$RESTtaskDC = $RESTtaskDC -replace "url=https://localhost", "url=https://$($FQDN):4242"
$RESTtaskDC = $RESTtaskDC -replace "method=GET;", "method=GET;sendExpect100Continue=true;"
$RESTtaskDC = $RESTtaskDC -replace "useCertificate=No;certificateStoreLocation=CurrentUser;", "useCertificate=FromFile;certificateStoreLocation=LocalMachine;"
$RESTtaskDC = $RESTtaskDC -replace "authSchema=ntlm", "authSchema=anonymous"
$RESTtaskDC = $RESTtaskDC -replace "certificateStoreName=My;", "certificateStoreName=My;certificateFilePath=$($FQDN)\\client.pfx;"
$RESTtaskDC = $RESTtaskDC -replace "queryHeaders=X-Qlik-XrfKey%20000000000000000%1User-Agent%2Windows", "queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api"
$RESTtaskDC = $RESTtaskDC -replace "%%password%2Qlik123!%1", "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTtaskID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTtaskDC
#Monitor_apps_rest_task
#---------------------------
$RESTuser = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/full?filter=(name eq 'monitor_apps_REST_user')&xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert 
$RESTuserID = $RESTuser.id
$RESTuserDC = Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTuserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Get -Headers $headers -ContentType 'application/json' -Certificate $cert
$RESTuserDC = $RESTuserDC | ConvertTo-Json
$RESTuserDC = $RESTuserDC -replace "url=https://localhost", "url=https://$($FQDN):4242"
$RESTuserDC = $RESTuserDC -replace "method=GET;", "method=GET;sendExpect100Continue=true;"
$RESTuserDC = $RESTuserDC -replace "useCertificate=No;certificateStoreLocation=CurrentUser;", "useCertificate=FromFile;certificateStoreLocation=LocalMachine;"
$RESTuserDC = $RESTuserDC -replace "authSchema=ntlm", "authSchema=anonymous"
$RESTuserDC = $RESTuserDC -replace "certificateStoreName=My;", "certificateStoreName=My;certificateFilePath=$($FQDN)\\client.pfx;"
$RESTuserDC = $RESTuserDC -replace "queryHeaders=X-Qlik-XrfKey%20000000000000000%1User-Agent%2Windows", "queryHeaders=X-Qlik-XrfKey%20000000000000000%1X-Qlik-User%2UserDirectory%%2INTERNAL%%1 %%userid%%2sa_api"
$RESTuserDC = $RESTuserDC -replace "%%password%2Qlik123!%1", "%%password%2Qlik123!%1certificateKey%2$($passwordCert.Password)%1"
Invoke-RestMethod -Uri "https://$($FQDN):4242/qrs/dataconnection/$($RESTuserID)?xrfkey=NzU0NTIwMDAwNTIy" -Method Put -Headers $headers -ContentType 'application/json' -Certificate $cert -Body $RESTuserDC
#--------------------------------------