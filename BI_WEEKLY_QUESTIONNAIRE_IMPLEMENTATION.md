# Bi-Weekly Questionnaire Restriction Implementation

## 🎯 **Overview**

I've implemented a bi-weekly restriction system for the Mental Health Questionnaire that prevents students from taking the questionnaire more than once every 14 days. This ensures meaningful assessment intervals and prevents survey fatigue.

## 🔧 **How It Works**

### **1. Database Query**
When the questionnaire page loads, the system:
```sql
SELECT submission_timestamp 
FROM questionnaire_responses 
WHERE user_id = ? 
ORDER BY submission_timestamp DESC 
LIMIT 1;
```

### **2. Time Calculation**
- Retrieves the user's most recent submission timestamp
- Calculates days elapsed since last submission
- Determines if 14+ days have passed
- Calculates next available date (last submission + 14 days)

### **3. User Experience**
- **Can Take**: Shows normal questionnaire introduction and questions
- **Cannot Take**: Shows restriction screen with helpful information

## 🎨 **User Interface**

### **Restriction Screen Features**
- **Clear messaging**: Explains the 2-week policy
- **Date information**: Shows last completion and next available date
- **Days countdown**: Visual indicator of remaining wait time
- **Alternative actions**: Suggests other app activities
- **Professional design**: Maintains app's visual consistency

### **Alternative Activities Suggested**
1. **View Previous Summaries** - Review past questionnaire results
2. **Try Breathing Exercises** - Practice mindfulness techniques  
3. **Mood Journal** - Track daily emotions and thoughts

## 💾 **Database Structure Used**

### **questionnaire_responses Table**
```sql
CREATE TABLE public.questionnaire_responses (
  response_id integer PRIMARY KEY,
  user_id uuid NOT NULL,
  version_id integer NOT NULL,
  total_score integer NOT NULL,
  submission_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
```

### **Key Fields**
- `user_id`: Links responses to specific users
- `submission_timestamp`: Tracks when each questionnaire was completed
- Used for calculating 14-day intervals

## 🚀 **Implementation Details**

### **New State Variables**
```dart
bool canTakeQuestionnaire = true;
DateTime? lastSubmissionDate;
DateTime? nextAvailableDate;
```

### **Key Methods Added**

#### **1. `_checkBiWeeklyRestriction()`**
- Queries user's latest questionnaire submission
- Calculates time difference from current date
- Sets restriction state and loads questionnaire if allowed

#### **2. `_buildRestrictionScreen()`**
- Creates professional UI for restricted access
- Shows last submission date and next available date
- Provides alternative activity suggestions
- Maintains consistent app styling

### **Flow Logic**
```dart
initState() → _checkBiWeeklyRestriction() → {
  if (canTake) → _loadActiveQuestionnaire() → showQuestionnaire
  if (cannot) → showRestrictionScreen
}
```

## ⚡ **Benefits**

### **1. Prevents Survey Fatigue**
- 14-day intervals ensure thoughtful responses
- Reduces user burnout from frequent questionnaires
- Maintains data quality and reliability

### **2. Professional User Experience**
- Clear communication about restriction policy
- Helpful alternative activities suggested
- Consistent visual design and messaging

### **3. Flexible System**
- Easy to modify restriction period (change `>= 14` to different value)
- Extensible for different questionnaire types
- Maintainable code structure

## 🔍 **Testing Scenarios**

### **Test Case 1: First Time User**
- **Expected**: Can take questionnaire immediately
- **Result**: No previous submissions found, questionnaire loads normally

### **Test Case 2: Recent Submission (< 14 days)**
- **Expected**: Shows restriction screen with countdown
- **Result**: Cannot access questionnaire, shows next available date

### **Test Case 3: Eligible User (≥ 14 days)**
- **Expected**: Can take questionnaire normally
- **Result**: Questionnaire loads and functions as before

### **Test Case 4: Database Error**
- **Expected**: Graceful error handling
- **Result**: Shows restriction screen to be safe

## 📊 **Data Insights**

The system tracks:
- **Last submission date**: When user completed questionnaire
- **Days elapsed**: Time since last completion
- **Next available date**: When user can take questionnaire again
- **Restriction status**: Whether user can currently access questionnaire

## 🛠️ **Customization Options**

### **Change Restriction Period**
```dart
// Change this line in _checkBiWeeklyRestriction():
final canTake = daysSinceLastSubmission >= 14; // Change 14 to desired days
```

### **Add Testing Override**
```dart
// Add debug flag for testing:
final bool debugMode = false; // Set to true for testing
final canTake = debugMode || daysSinceLastSubmission >= 14;
```

### **Different Messages**
Customize messages in `_buildRestrictionScreen()` method for different wording or languages.

## 🎉 **Ready to Test**

The bi-weekly restriction is now fully implemented and ready for testing:

1. **New users** can take the questionnaire immediately
2. **Recent users** see a professional restriction screen
3. **Eligible users** can take the questionnaire after 14+ days
4. **All users** get helpful alternative activity suggestions

The system maintains data integrity while providing an excellent user experience! 🚀