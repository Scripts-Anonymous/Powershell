get-aduser -identity $env:USERNAME |
set-aduser -SmartCardLogonRequired:$true