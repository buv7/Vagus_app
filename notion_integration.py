#!/usr/bin/env python3
"""
Notion API Integration Script for VAGUS App Documentation
This script creates and manages comprehensive project documentation in Notion.
"""

import requests
import json
import time
from typing import Dict, List, Any, Optional
import os

class NotionIntegration:
    def __init__(self, token: str):
        self.token = token
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
            'Notion-Version': '2022-06-28'
        }
        self.base_url = 'https://api.notion.com/v1'

    def search_pages(self, query: str = "") -> List[Dict]:
        """Search for pages in the workspace"""
        url = f"{self.base_url}/search"
        data = {
            "filter": {
                "value": "page",
                "property": "object"
            }
        }
        if query:
            data["query"] = query

        response = requests.post(url, headers=self.headers, json=data)
        if response.status_code == 200:
            return response.json().get('results', [])
        else:
            print(f"Error searching pages: {response.status_code} - {response.text}")
            return []

    def create_page(self, parent_id: str, title: str, properties: Dict = None) -> Optional[Dict]:
        """Create a new page in Notion"""
        url = f"{self.base_url}/pages"

        data = {
            "parent": {"page_id": parent_id},
            "properties": {
                "title": {
                    "title": [
                        {
                            "text": {
                                "content": title
                            }
                        }
                    ]
                }
            }
        }

        if properties:
            data["properties"].update(properties)

        response = requests.post(url, headers=self.headers, json=data)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error creating page: {response.status_code} - {response.text}")
            return None

    def add_blocks_to_page(self, page_id: str, blocks: List[Dict]) -> bool:
        """Add content blocks to a page"""
        url = f"{self.base_url}/blocks/{page_id}/children"

        # Notion has a limit of 100 blocks per request
        chunk_size = 100
        for i in range(0, len(blocks), chunk_size):
            chunk = blocks[i:i + chunk_size]
            data = {"children": chunk}

            response = requests.patch(url, headers=self.headers, json=data)
            if response.status_code != 200:
                print(f"Error adding blocks: {response.status_code} - {response.text}")
                return False

            # Rate limiting - be nice to Notion's API
            time.sleep(0.1)

        return True

    def create_text_block(self, text: str, block_type: str = "paragraph") -> Dict:
        """Create a text block"""
        return {
            "object": "block",
            "type": block_type,
            block_type: {
                "rich_text": [
                    {
                        "type": "text",
                        "text": {
                            "content": text
                        }
                    }
                ]
            }
        }

    def create_heading_block(self, text: str, level: int = 1) -> Dict:
        """Create a heading block (h1, h2, h3)"""
        heading_type = f"heading_{level}"
        return {
            "object": "block",
            "type": heading_type,
            heading_type: {
                "rich_text": [
                    {
                        "type": "text",
                        "text": {
                            "content": text
                        }
                    }
                ]
            }
        }

    def create_bulleted_list_block(self, text: str) -> Dict:
        """Create a bulleted list item"""
        return {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [
                    {
                        "type": "text",
                        "text": {
                            "content": text
                        }
                    }
                ]
            }
        }

    def create_code_block(self, code: str, language: str = "dart") -> Dict:
        """Create a code block"""
        return {
            "object": "block",
            "type": "code",
            "code": {
                "rich_text": [
                    {
                        "type": "text",
                        "text": {
                            "content": code
                        }
                    }
                ],
                "language": language
            }
        }

    def create_checkbox_block(self, text: str, checked: bool = False) -> Dict:
        """Create a checkbox/todo item"""
        return {
            "object": "block",
            "type": "to_do",
            "to_do": {
                "rich_text": [
                    {
                        "type": "text",
                        "text": {
                            "content": text
                        }
                    }
                ],
                "checked": checked
            }
        }

    def create_divider_block(self) -> Dict:
        """Create a divider/separator"""
        return {
            "object": "block",
            "type": "divider",
            "divider": {}
        }

    def create_vagus_documentation(self, parent_page_id: str) -> Optional[str]:
        """Create the complete VAGUS app documentation"""

        # Create main documentation page
        main_page = self.create_page(parent_page_id, "VAGUS App - Comprehensive Project Documentation")
        if not main_page:
            return None

        page_id = main_page['id']

        # Build the content blocks
        blocks = []

        # Table of Contents
        blocks.extend([
            self.create_heading_block("📋 Table of Contents", 2),
            self.create_bulleted_list_block("Project Overview"),
            self.create_bulleted_list_block("Tech Stack & Dependencies"),
            self.create_bulleted_list_block("Architecture Overview"),
            self.create_bulleted_list_block("Features Documentation"),
            self.create_bulleted_list_block("Service Layer Architecture"),
            self.create_bulleted_list_block("Data Models & Structures"),
            self.create_bulleted_list_block("UI Components & Widgets"),
            self.create_bulleted_list_block("Testing Strategy"),
            self.create_bulleted_list_block("File Structure"),
            self.create_bulleted_list_block("Setup & Development"),
            self.create_divider_block()
        ])

        # Project Overview
        blocks.extend([
            self.create_heading_block("🏗️ Project Overview", 2),
            self.create_heading_block("Project Name & Purpose", 3),
            self.create_text_block("VAGUS - AI-Powered Fitness & Nutrition App"),
            self.create_text_block("VAGUS is a comprehensive Flutter mobile application that provides AI-powered fitness and nutrition coaching, built with Supabase backend and OneSignal push notifications. The platform serves both coaches and clients with role-based access and features."),

            self.create_heading_block("Current Version", 3),
            self.create_bulleted_list_block("Version: 0.9.0+90"),
            self.create_bulleted_list_block("Flutter SDK: ^3.8.1"),
            self.create_bulleted_list_block("Platform: Cross-platform (iOS/Android)"),

            self.create_heading_block("Key Design Patterns", 3),
            self.create_bulleted_list_block("Singleton Pattern: All services use singleton pattern for global access"),
            self.create_bulleted_list_block("Repository Pattern: Services abstract data access from business logic"),
            self.create_bulleted_list_block("Service-Oriented Architecture: Clean separation of concerns across domains"),
            self.create_bulleted_list_block("Reactive Programming: ValueNotifier and Stream-based state management"),
            self.create_bulleted_list_block("Feature-Driven Development: Code organized by business domains"),
            self.create_divider_block()
        ])

        # Tech Stack
        blocks.extend([
            self.create_heading_block("🛠️ Tech Stack & Dependencies", 2),
            self.create_heading_block("Core Framework", 3),
            self.create_bulleted_list_block("Flutter SDK: ^3.8.1 (Cross-platform mobile development)"),
            self.create_bulleted_list_block("Dart: Latest stable version"),

            self.create_heading_block("Backend & Database", 3),
            self.create_bulleted_list_block("Supabase Flutter: ^2.9.1 (Backend integration, auth, real-time)"),
            self.create_bulleted_list_block("PostgreSQL: Database with Row Level Security (RLS)"),
            self.create_bulleted_list_block("Edge Functions: Serverless backend logic"),
            self.create_bulleted_list_block("Storage Buckets: File upload and management"),

            self.create_heading_block("Key Dependencies", 3),
            self.create_text_block("UI & Visualization:"),
            self.create_bulleted_list_block("FL Chart: ^0.66.0 (Data visualization and charts)"),
            self.create_bulleted_list_block("Lottie: ^2.7.0 (Complex animations)"),
            self.create_bulleted_list_block("Rive: ^0.13.13 (Interactive animations)"),
            self.create_bulleted_list_block("Photo View: ^0.15.0 (Image viewing)"),
            self.create_divider_block()
        ])

        # Features Documentation
        blocks.extend([
            self.create_heading_block("✨ Features Documentation", 2),
            self.create_heading_block("1. Admin Features & Support Systems", 3),
            self.create_text_block("Core Admin Panel:"),
            self.create_bulleted_list_block("User Role Management: Change user roles (client/coach/admin)"),
            self.create_bulleted_list_block("User Account Control: Enable/disable user accounts"),
            self.create_bulleted_list_block("Support Request Monitoring: Real-time urgent/attention/recent request tracking"),
            self.create_bulleted_list_block("Live Support Chat: Direct messaging with users needing assistance"),
            self.create_bulleted_list_block("CSV Export: Export user data for analytics"),
            self.create_bulleted_list_block("Search & Filtering: Find users by name, email, or role"),

            self.create_heading_block("2. Nutrition Features & AI Capabilities", 3),
            self.create_text_block("Nutrition Planning:"),
            self.create_bulleted_list_block("Modern Nutrition Plan Builder: Interactive plan creation"),
            self.create_bulleted_list_block("Recipe Management: Custom recipe database"),
            self.create_bulleted_list_block("Meal Planning: Daily/weekly meal scheduling"),
            self.create_bulleted_list_block("Macro Tracking: Protein, carbs, fat, calorie monitoring"),
            self.create_bulleted_list_block("Food Database: Extensive food item catalog"),
            self.create_bulleted_list_block("Nutrition AI: AI-powered food recognition and estimation"),

            self.create_heading_block("3. Workout & Fitness Features", 3),
            self.create_text_block("Workout Planning:"),
            self.create_bulleted_list_block("Modern Plan Builder: Interactive workout creation"),
            self.create_bulleted_list_block("Exercise Catalog: Comprehensive exercise database"),
            self.create_bulleted_list_block("Workout Plan Viewer: Client workout display"),
            self.create_bulleted_list_block("Cardio Logging: Cardiovascular exercise tracking"),
            self.create_bulleted_list_block("Exercise History: Performance tracking over time"),
            self.create_divider_block()
        ])

        # Testing Strategy
        blocks.extend([
            self.create_heading_block("🧪 Testing Strategy", 2),
            self.create_heading_block("Current Testing Setup", 3),
            self.create_code_block("""test/
├── calendar_peek_service_dst_test.dart      # Service testing
├── exercise_sheet_prefs_plumbing_test.dart  # Preferences testing
├── local_set_log_backcompat_test.dart       # Backward compatibility
├── progression_rules_advanced_test.dart     # Business logic testing
├── quickbook_reschedule_parser_test.dart    # Parser testing
├── set_type_format_test.dart                # Formatting testing
├── severity_colors_test.dart                # UI utility testing
├── user_prefs_service_test.dart             # Service testing
└── widget_test.dart                         # Placeholder widget test""", "text"),

            self.create_heading_block("Testing Checklist", 3),
            self.create_text_block("Unit Tests Needed:"),
            self.create_checkbox_block("All service classes unit tests"),
            self.create_checkbox_block("All model serialization/deserialization tests"),
            self.create_checkbox_block("All utility function tests"),
            self.create_checkbox_block("All business logic validation tests"),
            self.create_checkbox_block("All custom widget tests"),

            self.create_text_block("Integration Tests Required:"),
            self.create_checkbox_block("Supabase integration tests"),
            self.create_checkbox_block("Authentication flow tests"),
            self.create_checkbox_block("File upload/download tests"),
            self.create_checkbox_block("Real-time messaging tests"),
            self.create_checkbox_block("Payment processing tests"),
            self.create_checkbox_block("AI service integration tests"),
            self.create_divider_block()
        ])

        # Setup & Development
        blocks.extend([
            self.create_heading_block("🚀 Setup & Development", 2),
            self.create_heading_block("Prerequisites", 3),
            self.create_bulleted_list_block("Flutter SDK: Latest stable version (3.8.1+)"),
            self.create_bulleted_list_block("Supabase Account: For backend services"),
            self.create_bulleted_list_block("Android Studio or Xcode: For platform-specific builds"),
            self.create_bulleted_list_block("Git: Version control"),

            self.create_heading_block("Installation Steps", 3),
            self.create_text_block("1. Clone the Repository:"),
            self.create_code_block("git clone <repository-url>\ncd vagus_app", "bash"),

            self.create_text_block("2. Install Dependencies:"),
            self.create_code_block("flutter pub get", "bash"),

            self.create_text_block("3. Configure Supabase:"),
            self.create_bulleted_list_block("Create a new Supabase project"),
            self.create_bulleted_list_block("Run database migrations from supabase/migrations/"),
            self.create_bulleted_list_block("Set environment variables"),

            self.create_heading_block("How to Run Locally", 3),
            self.create_code_block("# Development Mode\nflutter run\n\n# Debug Mode with Hot Reload\nflutter run --debug\n\n# Release Mode Testing\nflutter run --release", "bash")
        ])

        # Add all blocks to the page
        success = self.add_blocks_to_page(page_id, blocks)

        if success:
            print(f"✅ Successfully created VAGUS documentation page!")
            print(f"📄 Page ID: {page_id}")
            return page_id
        else:
            print("❌ Failed to add content to the page")
            return None

def main():
    # Your Notion integration token
    token = os.environ.get("NOTION_TOKEN")
    if not token:
        print("NOTION_TOKEN env var is required. Set it securely and retry.")
        return

    # Initialize the integration
    notion = NotionIntegration(token)

    # Test connection by searching for pages
    print("🔍 Searching for pages in your workspace...")
    pages = notion.search_pages()

    if not pages:
        print("❌ No pages found. Make sure your integration has access to your workspace.")
        print("Go to your Notion workspace settings and connect the integration.")
        return

    print(f"✅ Found {len(pages)} pages in your workspace!")

    # List available pages
    print("\n📄 Available pages:")
    for i, page in enumerate(pages[:10]):  # Show first 10 pages
        title = "Untitled"
        if 'properties' in page and 'title' in page['properties']:
            title_prop = page['properties']['title']
            if 'title' in title_prop and title_prop['title']:
                title = title_prop['title'][0]['text']['content']
        elif 'properties' in page and 'Name' in page['properties']:
            name_prop = page['properties']['Name']
            if 'title' in name_prop and name_prop['title']:
                title = name_prop['title'][0]['text']['content']

        print(f"  {i+1}. {title} (ID: {page['id']})")

    # Ask user to select a parent page or create in first page
    if pages:
        parent_page_id = pages[0]['id']  # Use first page as parent
        print(f"\n🚀 Creating VAGUS documentation in the first page...")

        # Create the documentation
        doc_page_id = notion.create_vagus_documentation(parent_page_id)

        if doc_page_id:
            print(f"\n🎉 Success! Your VAGUS documentation has been created!")
            print(f"📄 You can view it at: https://notion.so/{doc_page_id.replace('-', '')}")
        else:
            print("\n❌ Failed to create documentation. Check the error messages above.")

if __name__ == "__main__":
    main()