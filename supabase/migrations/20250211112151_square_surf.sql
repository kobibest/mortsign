/*
  # Initial Schema Setup for Digital Signature Platform

  1. New Tables
    - profiles
      - Stores user profile information
      - Links to Supabase auth.users
    - documents
      - Stores document templates and content
      - Tracks document status and ownership
    - signatures
      - Records signature events
      - Links documents to signers

  2. Security
    - RLS policies for all tables
    - Secure access patterns for document sharing
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  email text NOT NULL,
  full_name text,
  company_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create documents table
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid REFERENCES auth.users(id) NOT NULL,
  title text NOT NULL,
  content text NOT NULL,
  template_html text NOT NULL,
  status text NOT NULL DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create signatures table
CREATE TABLE IF NOT EXISTS signatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid REFERENCES documents(id) NOT NULL,
  signer_email text NOT NULL,
  signer_name text NOT NULL,
  signature_data text,
  signed_at timestamptz,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE signatures ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Documents policies
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  TO authenticated
  USING (creator_id = auth.uid());

CREATE POLICY "Users can create documents"
  ON documents FOR INSERT
  TO authenticated
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "Users can update own documents"
  ON documents FOR UPDATE
  TO authenticated
  USING (creator_id = auth.uid());

-- Signatures policies
CREATE POLICY "Users can view signatures for their documents"
  ON signatures FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = signatures.document_id
      AND documents.creator_id = auth.uid()
    )
  );

CREATE POLICY "Users can create signatures"
  ON signatures FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM documents
      WHERE documents.id = signatures.document_id
      AND documents.creator_id = auth.uid()
    )
  );