# AI Food Recognition Setup Guide

The VAGUS app uses **Google Gemini AI** for food recognition from photos. This is a free service that can identify food items and estimate their nutritional content.

## Getting Your Free Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Click "Get API Key" in the top right
4. Create a new API key or use an existing one
5. Copy the API key

## Adding the API Key to Your App

Add the following line to your `.env` file in the project root:

```env
GEMINI_API_KEY=AIzaSyD1pMLL6gg5iqn1uTCBmEW8v07a_RI5hNw
```

## Free Tier Limits

Google Gemini has generous free tier limits:

| Model | Free Tier Limit |
|-------|-----------------|
| Gemini 1.5 Flash | 15 requests per minute |
| Gemini 1.5 Flash | 1 million tokens per minute |
| Gemini 1.5 Flash | 1,500 requests per day |

This is more than enough for a fitness/nutrition app for personal use.

## Optional: CalorieNinjas API

For text-based food nutrition lookup (not photo), you can also add:

```env
CALORIE_NINJAS_API_KEY=your_api_key_here
```

Get a free API key at [CalorieNinjas](https://calorieninjas.com/)
- 10,000 free API calls per month
- Note: Free tier is for non-commercial use only

## How It Works

1. **Take Photo**: User takes a photo of their food
2. **AI Analysis**: Google Gemini analyzes the image
3. **Food Recognition**: AI identifies the food items
4. **Nutrition Estimation**: AI estimates calories, protein, carbs, fat
5. **Quick Log**: Food is saved to the nutrition database

## Fallback Behavior

If the API key is not configured or the AI fails:
- The app will show a warning in the UI
- A basic fallback estimation will be provided
- Users can still manually edit the values

## Testing

To test if the AI is working:
1. Open the app
2. Go to the camera FAB menu
3. Tap "OCR Meal"
4. Look for the green "AI Powered by Google Gemini" indicator
5. Take a photo of food and tap "Analyze Photo"
