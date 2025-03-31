# PowerShell Script to Send HTML Email to Multiple Recipients
$smtpServer = "smtp.aol.com"  # Your SMTP server (You can replace it with your own SMTP provider)
$smtpFrom = "jchung@monmouth.com"    # Sender email address
$senderName = "Chung, Joseph"        # Sender name (This can be anything, like 'Weiho' or another name)
$subject = "Re: Important Announcement"   # Subject line

# Load email body from the external HTML file
$body = Get-Content -Path "C:\Users\wadoy\Desktop\2025RA\CyberSecurity\\chungemail\fakechung.txt" -Raw

# Create Mail Message Object
$message = New-Object System.Net.Mail.MailMessage
$message.From = New-Object System.Net.Mail.MailAddress($smtpFrom, $senderName)  # Customize 'From' name here
$message.Subject = $subject
$message.Body = $body
$message.IsBodyHtml = $true

# Updated List of Recipients (add more emails here)
$recipients = @(
    "s1366938@monmouth.edu",
    "wqu@monmouth.edu"
)

# Add each recipient to BCC (Blind Carbon Copy)
foreach ($recipient in $recipients) {
    $message.Bcc.Add($recipient)
}

# Set up SMTP Client
$smtp = New-Object Net.Mail.SmtpClient($smtpServer, 587)  # Adjust the port if necessary
$smtp.EnableSsl = $true  # Enable SSL/TLS encryption

# Try sending the email and catch errors
try {
    $smtp.Send($message)
    Write-Host "Emails sent successfully!"  # Confirmation message
} catch {
    Write-Host "Failed to send email: $_"  # Display any errors
}
