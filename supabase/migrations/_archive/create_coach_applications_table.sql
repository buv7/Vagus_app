-- Create coach_applications table for handling coach applications
CREATE TABLE IF NOT EXISTS public.coach_applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bio text NOT NULL,
  specialization text NOT NULL,
  years_experience integer NOT NULL DEFAULT 0,
  certifications text NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  reviewed_by uuid REFERENCES auth.users(id),
  review_notes text
);

-- Enable Row Level Security
ALTER TABLE public.coach_applications ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their own applications" ON public.coach_applications;
CREATE POLICY "Users can view their own applications" ON public.coach_applications
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own applications" ON public.coach_applications;
CREATE POLICY "Users can insert their own applications" ON public.coach_applications
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own pending applications" ON public.coach_applications;
CREATE POLICY "Users can update their own pending applications" ON public.coach_applications
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- Admin policies for reviewing applications
DROP POLICY IF EXISTS "Admins can view all applications" ON public.coach_applications;
CREATE POLICY "Admins can view all applications" ON public.coach_applications
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can update application status" ON public.coach_applications;
CREATE POLICY "Admins can update application status" ON public.coach_applications
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Indexes for performance
CREATE INDEX IF NOT EXISTS coach_applications_user_id_idx ON public.coach_applications (user_id);
CREATE INDEX IF NOT EXISTS coach_applications_status_idx ON public.coach_applications (status);
CREATE INDEX IF NOT EXISTS coach_applications_created_at_idx ON public.coach_applications (created_at DESC);

-- Unique constraint to prevent multiple pending applications from same user
CREATE UNIQUE INDEX IF NOT EXISTS coach_applications_user_pending_uidx 
ON public.coach_applications (user_id) 
WHERE status = 'pending';
