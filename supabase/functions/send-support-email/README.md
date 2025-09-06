# send-support-email (optional)

This Edge Function handles sending email notifications when support staff reply to tickets.

## Expected JSON Body

```json
{
  "type": "support_reply",
  "to": "user@example.com",
  "ticketId": "uuid",
  "subject": "Re: Title",
  "body": "Reply text"
}
```

## Implementation Notes

- **Type**: Always `"support_reply"` for now
- **To**: Recipient email address (ticket requester)
- **TicketId**: UUID of the support ticket
- **Subject**: Email subject line (prefixed with "Re: ")
- **Body**: The reply content from support staff

## Email Provider Integration

Integrate with your preferred email provider:
- SendGrid
- Mailgun
- AWS SES
- SMTP server
- etc.

## Graceful Degradation

The Flutter app gracefully handles missing Edge Functions:
- If function is not deployed, errors are swallowed
- Support functionality continues to work
- Only email notifications are skipped

## Security

- Function should validate admin/support staff permissions
- Rate limiting recommended
- Input validation required
- Log all email attempts for audit
