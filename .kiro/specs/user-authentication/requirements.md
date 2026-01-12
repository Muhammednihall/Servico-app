# Requirements Document: User Authentication with Role-Based Access

## Introduction

This feature enables users to register and log in to the Servico app with role-based access control. Users can choose between Customer or Worker roles during registration, and the app enforces role-specific access to services and features. Authentication is secure and persistent across sessions.

## Glossary

- **User**: A person using the Servico application
- **Customer**: A user role seeking services from workers
- **Worker**: A user role providing services to customers
- **Authentication**: The process of verifying user identity through credentials
- **Authorization**: The process of granting access based on user role
- **Session**: An authenticated user's active connection to the app
- **Credentials**: Username/email and password used for authentication
- **Role**: A designation (Customer or Worker) that determines app access and features

## Requirements

### Requirement 1: User Registration with Role Selection

**User Story:** As a new user, I want to register an account and select my role (Customer or Worker), so that I can access role-specific features and services.

#### Acceptance Criteria

1. WHEN a user opens the registration screen, THE System SHALL display a role selection interface with Customer and Worker options
2. WHEN a user selects a role and enters valid credentials (email, password, name), THE Firebase_Auth SHALL create a new user account via Firebase Authentication
3. WHEN a user attempts to register with an email that already exists, THE Firebase_Auth SHALL return an email-already-in-use error and THE System SHALL display "This email is already registered"
4. WHEN a user attempts to register with an invalid email format, THE Validator SHALL reject the input and display "Please enter a valid email address"
5. WHEN a user attempts to register with a password shorter than 8 characters, THE Validator SHALL reject the input and display "Password must be at least 8 characters"
6. WHEN a user attempts to register with an empty name field, THE Validator SHALL reject the input and display "Name is required"
7. WHEN registration is successful, THE Firebase_Auth SHALL create a user document in Firestore with role information (Customer or Worker)
8. WHEN registration is successful, THE System SHALL automatically log the user in and navigate to their role-specific home screen
9. WHEN a registration error occurs (network, Firebase service), THE System SHALL display a user-friendly error message and allow retry

### Requirement 2: Secure User Login

**User Story:** As a registered user, I want to log in securely with my credentials, so that I can access my account and role-specific services.

#### Acceptance Criteria

1. WHEN a user enters valid credentials (email and password), THE Firebase_Auth SHALL authenticate the user via Firebase Authentication and return a valid ID token
2. WHEN a user enters an invalid email format, THE Validator SHALL reject the input and display "Please enter a valid email address"
3. WHEN a user enters an invalid password (less than 8 characters), THE Validator SHALL reject the input and display "Password must be at least 8 characters"
4. WHEN a user enters invalid credentials, THE Firebase_Auth SHALL return an authentication error and THE System SHALL display "Invalid email or password" without revealing which field is incorrect
5. WHEN a user enters a non-existent email, THE Firebase_Auth SHALL return a user-not-found error and THE System SHALL display "No account found with this email"
6. WHEN a user successfully logs in, THE System SHALL store the Firebase ID token securely using Flutter Secure Storage
7. WHEN a user successfully logs in, THE System SHALL navigate to their role-specific home screen (Customer or Worker dashboard)
8. WHEN a user's Firebase session expires, THE System SHALL automatically refresh the token or log them out and return them to the login screen
9. WHEN a user closes and reopens the app, THE System SHALL check for an existing valid Firebase token and automatically log them in if one exists

### Requirement 3: Role-Based Access Control

**User Story:** As a user, I want the app to enforce my role permissions, so that I only see features and services relevant to my role.

#### Acceptance Criteria

1. WHEN a Customer logs in, THE System SHALL display the Customer home screen with service browsing and booking features
2. WHEN a Worker logs in, THE System SHALL display the Worker dashboard with job management and earnings features
3. WHEN a user attempts to access a screen not permitted for their role, THE System SHALL redirect them to their role-specific home screen
4. WHEN a user's role is Customer, THE System SHALL hide Worker-specific features (job management, earnings, availability toggle)
5. WHEN a user's role is Worker, THE System SHALL hide Customer-specific features (service browsing, booking)

### Requirement 4: Secure Logout

**User Story:** As a logged-in user, I want to log out securely, so that my account remains protected when I'm not using the app.

#### Acceptance Criteria

1. WHEN a user taps the logout button, THE Firebase_Auth SHALL sign out the user from Firebase Authentication
2. WHEN a user logs out, THE System SHALL delete the stored Firebase ID token from Flutter Secure Storage
3. WHEN a user logs out, THE System SHALL clear all cached user data and role information from memory
4. WHEN a user logs out, THE System SHALL navigate to the login screen
5. WHEN a user logs out, THE System SHALL prevent access to protected screens without re-authentication
6. WHEN a user logs out, THE System SHALL invalidate any active sessions on the backend

### Requirement 5: Session Persistence

**User Story:** As a user, I want my session to persist across app restarts, so that I don't have to log in every time I open the app.

#### Acceptance Criteria

1. WHEN a user logs in successfully, THE System SHALL store the Firebase ID token securely using Flutter Secure Storage
2. WHEN the app is closed and reopened, THE System SHALL retrieve the stored Firebase token from Flutter Secure Storage
3. WHEN a valid Firebase token exists and is not expired, THE System SHALL automatically restore the user session without requiring login
4. WHEN a stored token is expired or invalid, THE Firebase_Auth SHALL refresh the token automatically or clear it and require the user to log in again
5. WHEN a user logs out, THE System SHALL delete the stored Firebase token from Flutter Secure Storage and prevent automatic login

### Requirement 6: Password Security

**User Story:** As a user, I want my password to be securely stored and transmitted, so that my account remains protected.

#### Acceptance Criteria

1. WHEN a user registers or changes their password, THE Firebase_Auth SHALL hash the password using Firebase's built-in bcrypt algorithm before storing it
2. WHEN a user logs in, THE System SHALL transmit credentials over HTTPS only and never display the password in plain text
3. WHEN a user enters their password, THE System SHALL mask the input on the screen with dots or asterisks
4. WHEN a user's password is stored, THE Firebase_Auth SHALL use Firebase's industry-standard encryption and never store plain-text passwords
5. WHEN a user attempts to log in, THE Firebase_Auth SHALL securely compare the entered password against the stored hash using bcrypt verification
6. WHEN a user enters an incorrect password multiple times (3+ attempts), THE System SHALL temporarily lock the account and display "Too many login attempts. Please try again later"

### Requirement 7: Input Validation

**User Story:** As a user, I want the app to validate my input before submission, so that I receive clear feedback on what needs to be corrected.

#### Acceptance Criteria

1. WHEN a user enters an email, THE Validator SHALL check for valid email format (RFC 5322 standard) and display "Invalid email format" if incorrect
2. WHEN a user enters a password, THE Validator SHALL check minimum length (8 characters) and display "Password must be at least 8 characters" if too short
3. WHEN a user enters a name, THE Validator SHALL check that it is not empty and display "Name is required" if blank
4. WHEN a user enters a name, THE Validator SHALL check that it contains only letters, spaces, and hyphens, and display "Name contains invalid characters" if incorrect
5. WHEN a user submits a form with empty required fields, THE System SHALL highlight the empty fields and display "Please fill in all required fields"
6. WHEN a user enters text, THE System SHALL provide real-time validation feedback (green checkmark for valid, red X for invalid)
7. WHEN validation fails, THE System SHALL disable the submit button until all fields are valid

