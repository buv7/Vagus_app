-- Intake Forms v1 Schema
-- Migration: 0018_intake_forms_v1.sql

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Intake Forms table
CREATE TABLE IF NOT EXISTS intake_forms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coach_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    locale TEXT NOT NULL DEFAULT 'en',
    is_public BOOLEAN NOT NULL DEFAULT false,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    config_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Intake Form Versions table
CREATE TABLE IF NOT EXISTS intake_form_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_id UUID NOT NULL REFERENCES intake_forms(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    schema_json JSONB NOT NULL,
    waiver_md TEXT,
    active BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(form_id, version)
);

-- Intake Responses table
CREATE TABLE IF NOT EXISTS intake_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_id UUID NOT NULL REFERENCES intake_forms(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')),
    answers_json JSONB NOT NULL DEFAULT '{}',
    risk_score INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(form_id, client_id)
);

-- Intake Attachments table
CREATE TABLE IF NOT EXISTS intake_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    response_id UUID NOT NULL REFERENCES intake_responses(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Intake Signatures table
CREATE TABLE IF NOT EXISTS intake_signatures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    response_id UUID NOT NULL REFERENCES intake_responses(id) ON DELETE CASCADE,
    signed_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    signed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    signature_svg TEXT NOT NULL,
    waiver_hash TEXT NOT NULL,
    UNIQUE(response_id, signed_by)
);

-- Google Forms Links table (for future integration)
CREATE TABLE IF NOT EXISTS google_forms_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_id UUID NOT NULL REFERENCES intake_forms(id) ON DELETE CASCADE,
    external_id TEXT NOT NULL,
    map_json JSONB NOT NULL DEFAULT '{}',
    webhook_secret TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(form_id)
);

-- Intake Webhooks table (for future integration)
CREATE TABLE IF NOT EXISTS intake_webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_id UUID NOT NULL REFERENCES intake_forms(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    secret TEXT NOT NULL,
    last_status TEXT,
    last_called_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_intake_forms_coach_id ON intake_forms(coach_id);
CREATE INDEX IF NOT EXISTS idx_intake_forms_status ON intake_forms(status);
CREATE INDEX IF NOT EXISTS idx_intake_form_versions_form_id ON intake_form_versions(form_id);
CREATE INDEX IF NOT EXISTS idx_intake_form_versions_active ON intake_form_versions(active);
CREATE INDEX IF NOT EXISTS idx_intake_responses_form_id ON intake_responses(form_id);
CREATE INDEX IF NOT EXISTS idx_intake_responses_client_id ON intake_responses(client_id);
CREATE INDEX IF NOT EXISTS idx_intake_responses_status ON intake_responses(status);
CREATE INDEX IF NOT EXISTS idx_intake_attachments_response_id ON intake_attachments(response_id);
CREATE INDEX IF NOT EXISTS idx_intake_signatures_response_id ON intake_signatures(response_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_intake_forms_updated_at 
    BEFORE UPDATE ON intake_forms 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_intake_responses_updated_at 
    BEFORE UPDATE ON intake_responses 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies

-- Enable RLS on all tables
ALTER TABLE intake_forms ENABLE ROW LEVEL SECURITY;
ALTER TABLE intake_form_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE intake_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE intake_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE intake_signatures ENABLE ROW LEVEL SECURITY;
ALTER TABLE google_forms_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE intake_webhooks ENABLE ROW LEVEL SECURITY;

-- Intake Forms policies
CREATE POLICY "Coaches can manage their own forms" ON intake_forms
    FOR ALL USING (coach_id = auth.uid());

CREATE POLICY "Public forms are readable by all" ON intake_forms
    FOR SELECT USING (is_public = true OR coach_id IS NULL);

CREATE POLICY "Admins can read all forms" ON intake_forms
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Intake Form Versions policies
CREATE POLICY "Form versions follow form access" ON intake_form_versions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM intake_forms 
            WHERE id = form_id AND (
                coach_id = auth.uid() OR 
                is_public = true OR
                coach_id IS NULL OR
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() AND role = 'admin'
                )
            )
        )
    );

-- Intake Responses policies
CREATE POLICY "Clients can manage their own responses" ON intake_responses
    FOR ALL USING (client_id = auth.uid());

CREATE POLICY "Coaches can read client responses to their forms" ON intake_responses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM intake_forms 
            WHERE id = form_id AND (coach_id = auth.uid() OR coach_id IS NULL)
        )
    );

CREATE POLICY "Coaches can update response status" ON intake_responses
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM intake_forms 
            WHERE id = form_id AND (coach_id = auth.uid() OR coach_id IS NULL)
        )
    );

CREATE POLICY "Admins can read all responses" ON intake_responses
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Intake Attachments policies
CREATE POLICY "Attachments follow response access" ON intake_attachments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM intake_responses 
            WHERE id = response_id AND (
                client_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM intake_forms 
                    WHERE id = form_id AND (coach_id = auth.uid() OR coach_id IS NULL)
                ) OR
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() AND role = 'admin'
                )
            )
        )
    );

-- Intake Signatures policies
CREATE POLICY "Signatures follow response access" ON intake_signatures
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM intake_responses 
            WHERE id = response_id AND (
                client_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM intake_forms 
                    WHERE id = form_id AND (coach_id = auth.uid() OR coach_id IS NULL)
                ) OR
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() AND role = 'admin'
                )
            )
        )
    );

-- Google Forms Links policies
CREATE POLICY "Google forms links follow form access" ON google_forms_links
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM intake_forms 
            WHERE id = form_id AND (
                coach_id = auth.uid() OR
                coach_id IS NULL OR
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() AND role = 'admin'
                )
            )
        )
    );

-- Intake Webhooks policies
CREATE POLICY "Webhooks follow form access" ON intake_webhooks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM intake_forms 
            WHERE id = form_id AND (
                coach_id = auth.uid() OR
                coach_id IS NULL OR
                EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = auth.uid() AND role = 'admin'
                )
            )
        )
    );

-- Seed default form schema for native form
INSERT INTO intake_forms (id, coach_id, title, locale, is_public, status, config_json)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    NULL, -- System default form, no specific coach
    'Default Intake Form',
    'en',
    true,
    'published',
    '{
        "sections": [
            {
                "id": "profile",
                "title": "Profile Information",
                "fields": [
                    {"id": "name", "type": "text", "label": "Full Name", "required": true},
                    {"id": "email", "type": "email", "label": "Email", "required": true},
                    {"id": "phone", "type": "tel", "label": "Phone Number", "required": false},
                    {"id": "date_of_birth", "type": "date", "label": "Date of Birth", "required": true},
                    {"id": "gender", "type": "select", "label": "Gender", "options": ["Male", "Female", "Other", "Prefer not to say"], "required": false}
                ]
            },
            {
                "id": "goals",
                "title": "Fitness Goals",
                "fields": [
                    {"id": "primary_goal", "type": "select", "label": "Primary Goal", "options": ["Weight Loss", "Muscle Gain", "General Fitness", "Athletic Performance", "Rehabilitation", "Other"], "required": true},
                    {"id": "goal_description", "type": "textarea", "label": "Describe your specific goals", "required": false},
                    {"id": "timeline", "type": "select", "label": "Timeline", "options": ["1-3 months", "3-6 months", "6-12 months", "1+ years"], "required": false}
                ]
            },
            {
                "id": "training_history",
                "title": "Training History & Injuries",
                "fields": [
                    {"id": "experience_level", "type": "select", "label": "Experience Level", "options": ["Beginner", "Intermediate", "Advanced"], "required": true},
                    {"id": "previous_training", "type": "textarea", "label": "Previous training experience", "required": false},
                    {"id": "injuries", "type": "textarea", "label": "Current or past injuries", "required": false},
                    {"id": "medical_conditions", "type": "textarea", "label": "Medical conditions", "required": false}
                ]
            },
            {
                "id": "equipment",
                "title": "Equipment & Schedule",
                "fields": [
                    {"id": "equipment_available", "type": "multiselect", "label": "Available Equipment", "options": ["None", "Dumbbells", "Resistance Bands", "Pull-up Bar", "Bench", "Full Gym", "Other"], "required": false},
                    {"id": "workout_duration", "type": "select", "label": "Preferred workout duration", "options": ["15-30 minutes", "30-45 minutes", "45-60 minutes", "60+ minutes"], "required": false},
                    {"id": "workout_frequency", "type": "select", "label": "Workout frequency per week", "options": ["1-2 times", "3-4 times", "5-6 times", "Daily"], "required": false}
                ]
            },
            {
                "id": "lifestyle",
                "title": "Lifestyle & Sleep",
                "fields": [
                    {"id": "sleep_hours", "type": "number", "label": "Average hours of sleep per night", "required": false},
                    {"id": "stress_level", "type": "select", "label": "Stress level", "options": ["Low", "Moderate", "High"], "required": false},
                    {"id": "occupation", "type": "text", "label": "Occupation", "required": false}
                ]
            },
            {
                "id": "nutrition",
                "title": "Nutrition & Supplements",
                "fields": [
                    {"id": "dietary_restrictions", "type": "multiselect", "label": "Dietary restrictions", "options": ["None", "Vegetarian", "Vegan", "Gluten-free", "Dairy-free", "Keto", "Paleo", "Other"], "required": false},
                    {"id": "supplements", "type": "textarea", "label": "Current supplements", "required": false},
                    {"id": "allergies", "type": "textarea", "label": "Food allergies", "required": false}
                ]
            },
            {
                "id": "parq",
                "title": "Physical Activity Readiness Questionnaire (PAR-Q)",
                "fields": [
                    {"id": "heart_condition", "type": "radio", "label": "Has your doctor ever said you have a heart condition?", "options": ["Yes", "No"], "required": true},
                    {"id": "chest_pain", "type": "radio", "label": "Do you feel pain in your chest when you do physical activity?", "options": ["Yes", "No"], "required": true},
                    {"id": "dizziness", "type": "radio", "label": "Do you lose your balance because of dizziness or do you ever lose consciousness?", "options": ["Yes", "No"], "required": true},
                    {"id": "bone_problem", "type": "radio", "label": "Do you have a bone or joint problem that could be made worse by a change in your physical activity?", "options": ["Yes", "No"], "required": true},
                    {"id": "blood_pressure", "type": "radio", "label": "Is your doctor currently prescribing drugs for your blood pressure or heart condition?", "options": ["Yes", "No"], "required": true},
                    {"id": "physical_activity", "type": "radio", "label": "Do you know of any other reason why you should not do physical activity?", "options": ["Yes", "No"], "required": true}
                ]
            }
        ]
    }'
) ON CONFLICT (id) DO NOTHING;

-- Insert default form version
INSERT INTO intake_form_versions (form_id, version, schema_json, waiver_md, active)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    1,
    '{
        "sections": [
            {
                "id": "profile",
                "title": "Profile Information",
                "fields": [
                    {"id": "name", "type": "text", "label": "Full Name", "required": true},
                    {"id": "email", "type": "email", "label": "Email", "required": true},
                    {"id": "phone", "type": "tel", "label": "Phone Number", "required": false},
                    {"id": "date_of_birth", "type": "date", "label": "Date of Birth", "required": true},
                    {"id": "gender", "type": "select", "label": "Gender", "options": ["Male", "Female", "Other", "Prefer not to say"], "required": false}
                ]
            },
            {
                "id": "goals",
                "title": "Fitness Goals",
                "fields": [
                    {"id": "primary_goal", "type": "select", "label": "Primary Goal", "options": ["Weight Loss", "Muscle Gain", "General Fitness", "Athletic Performance", "Rehabilitation", "Other"], "required": true},
                    {"id": "goal_description", "type": "textarea", "label": "Describe your specific goals", "required": false},
                    {"id": "timeline", "type": "select", "label": "Timeline", "options": ["1-3 months", "3-6 months", "6-12 months", "1+ years"], "required": false}
                ]
            },
            {
                "id": "training_history",
                "title": "Training History & Injuries",
                "fields": [
                    {"id": "experience_level", "type": "select", "label": "Experience Level", "options": ["Beginner", "Intermediate", "Advanced"], "required": true},
                    {"id": "previous_training", "type": "textarea", "label": "Previous training experience", "required": false},
                    {"id": "injuries", "type": "textarea", "label": "Current or past injuries", "required": false},
                    {"id": "medical_conditions", "type": "textarea", "label": "Medical conditions", "required": false}
                ]
            },
            {
                "id": "equipment",
                "title": "Equipment & Schedule",
                "fields": [
                    {"id": "equipment_available", "type": "multiselect", "label": "Available Equipment", "options": ["None", "Dumbbells", "Resistance Bands", "Pull-up Bar", "Bench", "Full Gym", "Other"], "required": false},
                    {"id": "workout_duration", "type": "select", "label": "Preferred workout duration", "options": ["15-30 minutes", "30-45 minutes", "45-60 minutes", "60+ minutes"], "required": false},
                    {"id": "workout_frequency", "type": "select", "label": "Workout frequency per week", "options": ["1-2 times", "3-4 times", "5-6 times", "Daily"], "required": false}
                ]
            },
            {
                "id": "lifestyle",
                "title": "Lifestyle & Sleep",
                "fields": [
                    {"id": "sleep_hours", "type": "number", "label": "Average hours of sleep per night", "required": false},
                    {"id": "stress_level", "type": "select", "label": "Stress level", "options": ["Low", "Moderate", "High"], "required": false},
                    {"id": "occupation", "type": "text", "label": "Occupation", "required": false}
                ]
            },
            {
                "id": "nutrition",
                "title": "Nutrition & Supplements",
                "fields": [
                    {"id": "dietary_restrictions", "type": "multiselect", "label": "Dietary restrictions", "options": ["None", "Vegetarian", "Vegan", "Gluten-free", "Dairy-free", "Keto", "Paleo", "Other"], "required": false},
                    {"id": "supplements", "type": "textarea", "label": "Current supplements", "required": false},
                    {"id": "allergies", "type": "textarea", "label": "Food allergies", "required": false}
                ]
            },
            {
                "id": "parq",
                "title": "Physical Activity Readiness Questionnaire (PAR-Q)",
                "fields": [
                    {"id": "heart_condition", "type": "radio", "label": "Has your doctor ever said you have a heart condition?", "options": ["Yes", "No"], "required": true},
                    {"id": "chest_pain", "type": "radio", "label": "Do you feel pain in your chest when you do physical activity?", "options": ["Yes", "No"], "required": true},
                    {"id": "dizziness", "type": "radio", "label": "Do you lose your balance because of dizziness or do you ever lose consciousness?", "options": ["Yes", "No"], "required": true},
                    {"id": "bone_problem", "type": "radio", "label": "Do you have a bone or joint problem that could be made worse by a change in your physical activity?", "options": ["Yes", "No"], "required": true},
                    {"id": "blood_pressure", "type": "radio", "label": "Is your doctor currently prescribing drugs for your blood pressure or heart condition?", "options": ["Yes", "No"], "required": true},
                    {"id": "physical_activity", "type": "radio", "label": "Do you know of any other reason why you should not do physical activity?", "options": ["Yes", "No"], "required": true}
                ]
            }
        ]
    }',
    '# Waiver and Consent

By signing this form, I acknowledge that:

1. I have completed the Physical Activity Readiness Questionnaire (PAR-Q) truthfully
2. I understand that physical activity involves risk of injury
3. I will inform my coach of any changes in my health status
4. I consent to participate in the fitness program designed for me
5. I understand that results may vary and are not guaranteed

I release my coach and the fitness program from any liability for injuries that may occur during training.',
    true
) ON CONFLICT (form_id, version) DO NOTHING;
