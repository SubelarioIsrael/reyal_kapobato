# Intervention System Documentation

## Overview

The BreatheBetter app includes an intelligent intervention system that monitors student chat messages and automatically triggers notifications when concerning content is detected. This system helps ensure student safety and provides timely support for mental health concerns.

## Features

### 1. Real-time Message Analysis
- Monitors all chat messages in real-time
- Uses keyword and phrase detection to identify concerning content
- Analyzes message patterns and context

### 2. Multi-level Intervention System
- **Moderate Risk**: General mental health concerns, stress, anxiety
- **High Risk**: Crisis situations, self-harm, suicide ideation, abuse

### 3. Smart Notification System
- Sends personalized intervention notifications
- Prevents notification spam (6-hour cooldown)
- Links to appropriate resources and counselor pages

### 4. Privacy and Security
- All chat messages are stored securely with user authentication
- Automatic cleanup of old messages (30 days)
- Row-level security policies ensure data privacy

## Implementation Details

### Services

#### 1. InterventionService (`lib/services/intervention_service.dart`)
- **`analyzeMessage(String message)`**: Analyzes individual messages for concerning content
- **`analyzeRecentChatHistory()`**: Analyzes patterns in recent chat history
- **`triggerIntervention(InterventionLevel level, String triggerMessage)`**: Sends intervention notifications
- **`hasRecentIntervention()`**: Prevents notification spam

#### 2. ChatMessageService (`lib/services/chat_message_service.dart`)
- **`storeMessage(String messageContent, String sender)`**: Stores chat messages in database
- **`getRecentMessages()`**: Retrieves recent messages for analysis
- **`clearOldMessages()`**: Cleans up old messages for privacy

### Database Tables

#### 1. `chat_messages`
```sql
CREATE TABLE chat_messages (
    message_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id),
    message_content TEXT NOT NULL,
    sender VARCHAR(10) NOT NULL CHECK (sender IN ('user', 'bot')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. `intervention_logs`
```sql
CREATE TABLE intervention_logs (
    log_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id),
    intervention_level VARCHAR(20) NOT NULL CHECK (intervention_level IN ('moderate', 'high')),
    trigger_message TEXT NOT NULL,
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Detection Keywords

#### High-Risk Phrases (Immediate Intervention)
- Suicide-related: "suicide", "kill myself", "want to die", "end it all"
- Self-harm: "self harm", "cut myself", "hurt myself"
- Abuse: "abuse", "domestic violence", "sexual assault"

#### Concerning Keywords (Pattern Analysis)
- Mental health: "depression", "hopeless", "worthless", "anxiety"
- Crisis: "panic attack", "can't breathe", "heart attack"
- Substance abuse: "drugs", "alcohol", "overdose"
- Social issues: "bullying", "harassment", "lonely", "isolated"
- Stress: "overwhelmed", "can't cope", "breaking point"

## Usage

### For Students
1. Chat normally with the AI assistant
2. If concerning content is detected, you'll receive a notification
3. The notification will provide resources and recommendations
4. You can access counselor information through the app

### For Administrators
1. Access the Intervention Monitoring page (`admin_interventions.dart`)
2. View all intervention triggers and statistics
3. Monitor student mental health patterns
4. Filter by risk level and time period

## Setup Instructions

### 1. Database Setup
Run the SQL commands in `intervention_tables.sql` to create the necessary tables:

```bash
# Connect to your Supabase database and run:
psql -h your-supabase-host -U postgres -d postgres -f intervention_tables.sql
```

### 2. Flutter Integration
The intervention system is automatically integrated into the chatbot. No additional setup required.

### 3. Admin Access
Add the intervention monitoring page to your admin navigation:

```dart
// In your admin drawer or navigation
ListTile(
  leading: Icon(Icons.warning),
  title: Text('Intervention Monitoring'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const AdminInterventions()),
  ),
),
```

## Configuration

### Customizing Keywords
Edit the keyword lists in `InterventionService`:

```dart
static const List<String> _concerningKeywords = [
  // Add your custom keywords here
];

static const List<String> _highRiskPhrases = [
  // Add your high-risk phrases here
];
```

### Adjusting Sensitivity
Modify the detection thresholds:

```dart
// In analyzeMessage method
if (concerningCount >= 3) {  // Change from 3 to desired threshold
  return InterventionLevel.high;
} else if (concerningCount >= 1) {  // Change from 1 to desired threshold
  return InterventionLevel.moderate;
}
```

### Notification Cooldown
Adjust the notification cooldown period:

```dart
// In hasRecentIntervention method
final sixHoursAgo = DateTime.now().subtract(const Duration(hours: 6));  // Change hours as needed
```

## Privacy and Ethics

### Data Protection
- All chat messages are encrypted in transit and at rest
- Messages are automatically deleted after 30 days
- Users can only access their own data
- Row-level security policies enforce data isolation

### Ethical Considerations
- The system is designed to help, not punish
- Notifications are supportive and non-judgmental
- Students maintain control over their data
- Clear privacy policies and consent mechanisms

## Monitoring and Analytics

### Key Metrics
- Total interventions triggered
- High-risk vs moderate-risk distribution
- Daily/weekly intervention trends
- Most common trigger keywords

### Admin Dashboard Features
- Real-time intervention monitoring
- Student-specific intervention history
- Risk level filtering
- Export capabilities for reporting

## Support and Maintenance

### Regular Maintenance
- Monitor false positive rates
- Update keyword lists based on trends
- Review and adjust sensitivity thresholds
- Clean up old data regularly

### Troubleshooting
- Check database connectivity
- Verify Supabase permissions
- Monitor error logs for issues
- Test intervention triggers in development

## Future Enhancements

### Planned Features
- Machine learning-based content analysis
- Integration with external crisis hotlines
- Automated counselor notifications
- Advanced pattern recognition
- Multi-language support

### Research Opportunities
- Effectiveness of intervention timing
- Impact on student mental health outcomes
- Comparison with traditional support methods
- Long-term intervention success rates 