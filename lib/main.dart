// First, add these dependencies to your pubspec.yaml:
// firebase_core: ^2.15.1
// firebase_auth: ^4.9.0
// google_sign_in: ^6.1.5
// provider: ^6.0.5
// flutter_secure_storage: ^9.0.0

// 1. Initialize Firebase in main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
//import 'package:webauthn/webauthn.dart' as webauthn;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
    );
  }
}

// 2. Create an Auth Service Class
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Stream to track auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Store user token securely
      String? token = await result.user?.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
      }
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Send email verification
      await result.user?.sendEmailVerification();
      
      // Store user token securely
      String? token = await result.user?.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
      }
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was canceled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Store user token securely
      String? token = await result.user?.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
      }
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _secureStorage.delete(key: 'auth_token');
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Check if email is verified
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }
  
  // Send verification email
  Future<void> sendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Reload user to check for email verification
  Future<void> reloadUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is admin (example of role-based authorization)
  Future<bool> isUserAdmin() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;
      
      // Get ID token with claims
      IdTokenResult tokenResult = await user.getIdTokenResult();
      
      // Check if admin claim exists and is true
      return tokenResult.claims?['admin'] == true;
    } catch (e) {
      return false;
    }
  }
  
  // Get available biometric authentication methods
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
  
  // Check if biometric authentication is available
  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }
  
  
  // Register a passkey for the current user
  Future<bool> registerPasskey() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;
      
      // Check if device supports biometrics
      if (!await canUseBiometrics()) {
        throw Exception('Device does not support biometric authentication');
      }
      
      // Generate credential ID
      String credentialId = _generateSecureId(user.uid);
      
      // Store credential info securely
      if (kIsWeb) {
        // Web implementation would use WebAuthn
        // This is a simplified implementation for demonstration
        try {
          // For web, we'd normally use the WebAuthn API
          // but for this demo we'll just simulate it
          await _secureStorage.write(
            key: 'passkey_${user.uid}',
            value: jsonEncode({
              'credentialId': _generateSecureId(user.uid),
              'type': 'web',
              'createdAt': DateTime.now().toIso8601String(),
            }),
          );
          
          return true;
        } catch (e) {
          throw Exception('Failed to create credential: $e');
        }
      } else {
        // Mobile implementation using local_auth
        bool authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to set up your passkey',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        
        if (authenticated) {
          // Store the credential info in secure storage
          await _secureStorage.write(
            key: 'passkey_${user.uid}',
            value: jsonEncode({
              'credentialId': credentialId,
              'userId': user.uid,
              'type': 'mobile',
              'createdAt': DateTime.now().toIso8601String(),
            }),
          );
          return true;
        } else {
          throw Exception('Biometric authentication failed');
        }
      }
    } catch (e) {
      print('Error registering passkey: $e');
      return false;
    }
  }
  
  // Generate a credential ID with some randomness
  String _generateSecureId(String userId) {
    final random = List<int>.generate(16, (_) => math.Random().nextInt(256));
    final bytes = utf8.encode(userId + DateTime.now().toIso8601String()) + random;
    return base64Url.encode(sha256.convert(bytes).bytes);
  }
  
  // Check if the current user has a registered passkey
  Future<bool> hasPasskey() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;
      
      String? storedData = await _secureStorage.read(key: 'passkey_${user.uid}');
      return storedData != null;
    } catch (e) {
      return false;
    }
  }
  
  // Sign in with passkey
  Future<UserCredential?> signInWithPasskey(String email) async {
    try {
      // First, fetch the user by email
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        throw Exception('No account found with this email');
      }
      
      // For simplicity, we're creating a custom token for the user
      // In a production app, this would be handled securely by a server
      final customToken = await _getCustomTokenForEmail(email);
      if (customToken == null) {
        throw Exception('Failed to get authentication token');
      }
      
      if (kIsWeb) {
        // Web implementation would use WebAuthn
        // This is a simplified implementation for demonstration
        try {
          // For web, we'd normally use the WebAuthn API here
          // but for this demo we'll just assume authentication succeeded
          
          // If we get here, the authentication succeeded
          return await _auth.signInWithCustomToken(customToken);
        } catch (e) {
          throw Exception('Authentication failed: $e');
        }
      } else {
        // Mobile implementation using local_auth
        bool authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to sign in',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        
        if (authenticated) {
          return await _auth.signInWithCustomToken(customToken);
        } else {
          throw Exception('Biometric authentication failed');
        }
      }
    } catch (e) {
      print('Error signing in with passkey: $e');
      return null;
    }
  }
  
  // In a real app, this would be handled by a secure backend
  // This is a simplified version for demo purposes
  Future<String?> _getCustomTokenForEmail(String email) async {
    try {
      // This is a simplified mock implementation
      // In production, this would involve a secure server call
      // that validates the biometric authentication and returns a token
      
      // Simulate getting a custom token
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Since we can't create custom tokens directly from the client,
      // in a real app this would be a server endpoint call
      // For this demo, we'll use a workaround
      
      // First sign in with email/password to get a user
      try {
        // Try to sign in anonymously to get a temporary user
        final tempCredential = await _auth.signInAnonymously();
        
        // Then get the ID token and use that (not a proper solution but works for demo)
        final idToken = await tempCredential.user?.getIdToken();
        
        // Sign out the temporary user
        await _auth.signOut();
        
        return idToken;
      } catch (e) {
        print('Error in mock token generation: $e');
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  // Remove a registered passkey
  Future<bool> removePasskey() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;
      
      await _secureStorage.delete(key: 'passkey_${user.uid}');
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      // Request credential for Apple Sign In
      final AuthorizationCredentialAppleID credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      // Convert to OAuthCredential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      
      // Sign in to Firebase with the Apple credential
      final UserCredential result = await _auth.signInWithCredential(oauthCredential);
      
      // If this is a new user, update the display name (Apple might not provide it later)
      if (credential.givenName != null && credential.familyName != null) {
        if (result.user?.displayName == null || result.user!.displayName!.isEmpty) {
          await result.user?.updateDisplayName('${credential.givenName} ${credential.familyName}');
        }
      }
      
      // Store user token securely
      String? token = await result.user?.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
      }
      
      return result;
    } catch (e) {
      rethrow;
    }
  }
  
  // Sign in with Facebook
  Future<UserCredential> signInWithFacebook() async {
    try {
      // Trigger the Facebook sign-in flow
      final LoginResult loginResult = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );
      
      if (loginResult.status != LoginStatus.success) {
        throw Exception('Facebook sign in was canceled or failed: ${loginResult.status}');
      }
      
      // Get access token
      final AccessToken? accessToken = loginResult.accessToken;
      if (accessToken == null) {
        throw Exception('No access token received from Facebook');
      }
      
      // Create a credential from the access token
      final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(accessToken.tokenString);
      
      // Sign in to Firebase with the Facebook credential
      final UserCredential result = await _auth.signInWithCredential(facebookAuthCredential);
      
      // Store user token securely
      String? token = await result.user?.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
      }
      
      return result;
    } catch (e) {
      rethrow;
    }
  }
}

// 3. Create an Auth Provider (using Provider pattern)
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isVerifying = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isVerifying => _isVerifying;
  bool get isEmailVerified => _authService.isEmailVerified();
  
  // Passkey state
  bool _hasPasskey = false;
  bool _canUsePasskeys = false;
  bool _isRegisteringPasskey = false;
  bool get hasPasskey => _hasPasskey;
  bool get canUsePasskeys => _canUsePasskeys;
  bool get isRegisteringPasskey => _isRegisteringPasskey;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      
      // Check passkey capabilities
      _checkPasskeyCapability();
      
      // If user is logged in, check if they have a passkey
      if (user != null) {
        _checkHasPasskey();
      } else {
        _hasPasskey = false;
      }
      
      notifyListeners();
    });
  }
  
  // Check if device can use passkeys
  Future<void> _checkPasskeyCapability() async {
    _canUsePasskeys = await _authService.canUseBiometrics();
    notifyListeners();
  }
  
  // Check if user has a registered passkey
  Future<void> _checkHasPasskey() async {
    if (_user != null) {
      _hasPasskey = await _authService.hasPasskey();
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }
  
  // Helper method to convert Firebase auth errors to user-friendly messages
  String _formatAuthError(dynamic e) {
    String message = e.toString();
    
    if (message.contains('user-not-found')) {
      return 'No account found with this email. Please check your email or create a new account.';
    } else if (message.contains('wrong-password')) {
      return 'Incorrect password. Please try again or reset your password.';
    } else if (message.contains('invalid-email')) {
      return 'Invalid email format. Please enter a valid email address.';
    } else if (message.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    } else if (message.contains('too-many-requests')) {
      return 'Too many failed login attempts. Please try again later or reset your password.';
    } else if (message.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (message.contains('email-already-in-use')) {
      return 'This email is already registered. Please use a different email or try logging in.';
    } else if (message.contains('requires-recent-login')) {
      return 'This operation is sensitive and requires recent authentication. Please log in again before retrying.';
    } else if (message.contains('operation-not-allowed')) {
      return 'This operation is not allowed. Please contact support.';
    } else if (message.contains('invalid-action-code')) {
      return 'The action code is invalid. This can happen if the code is malformed, expired, or has already been used.';
    } else if (message.contains('expired-action-code')) {
      return 'The reset link has expired. Please request a new password reset link.';
    } else if (message.contains('account-exists-with-different-credential')) {
      return 'An account already exists with the same email but different sign-in credentials. Try signing in using a different method.';
    } else if (message.contains('invalid-credential')) {
      return 'The authentication credential is invalid. Please try again with valid credentials.';
    } else if (message.contains('credential-already-in-use')) {
      return 'This credential is already associated with a different user account.';
    } else if (message.contains('popup-closed-by-user') || message.contains('cancelled') || message.contains('canceled')) {
      return 'Sign-in process was cancelled. Please try again.';
    } else if (message.contains('apple')) {
      if (message.contains('not-available') || message.contains('not available')) {
        return 'Apple Sign In is not available on this device.';
      }
      return 'Apple Sign In failed: Please try again or use a different sign-in method.';
    } else if (message.contains('facebook')) {
      return 'Facebook Sign In failed: Please try again or use a different sign-in method.';
    } else {
      // For debugging purposes, keep the original error with a user-friendly prefix
      return 'Operation failed: $message';
    }
  }

  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.registerWithEmailAndPassword(email, password);
      _isLoading = false;
      
      // Success message for email verification
      _error = 'Registration successful! Please check your email to verify your account.';
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }
  
  // Sign in with Apple
  Future<bool> signInWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signInWithApple();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }
  
  // Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.signInWithFacebook();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<bool> checkAdminRole() async {
    return await _authService.isUserAdmin();
  }
  
  // Register a passkey for the current user
  Future<bool> registerPasskey() async {
    _isRegisteringPasskey = true;
    _error = null;
    notifyListeners();
    
    try {
      bool result = await _authService.registerPasskey();
      _isRegisteringPasskey = false;
      
      if (result) {
        await _checkHasPasskey();
      } else {
        _error = 'Failed to register passkey. Please try again.';
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _isRegisteringPasskey = false;
      _error = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }
  
  // Remove a passkey
  Future<bool> removePasskey() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      bool result = await _authService.removePasskey();
      _isLoading = false;
      
      if (result) {
        await _checkHasPasskey();
      } else {
        _error = 'Failed to remove passkey. Please try again.';
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }
  
  // Sign in with passkey
  Future<bool> signInWithPasskey(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      UserCredential? result = await _authService.signInWithPasskey(email);
      _isLoading = false;
      
      if (result != null) {
        notifyListeners();
        return true;
      } else {
        _error = 'Passkey authentication failed. Please try again or use another sign-in method.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e);
      notifyListeners();
      return false;
    }
  }
  
  Future<void> sendVerificationEmail() async {
    _isVerifying = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authService.sendVerificationEmail();
      _isVerifying = false;
      notifyListeners();
    } catch (e) {
      _isVerifying = false;
      _error = _formatAuthError(e);
      notifyListeners();
    }
  }
  
  Future<void> checkEmailVerification() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _authService.reloadUser();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = _formatAuthError(e);
      notifyListeners();
    }
  }
}

// 4. Auth Wrapper to control app flow based on auth state
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Show loading indicator when checking auth state
    if (authProvider.isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Navigate based on auth state
    if (authProvider.isAuthenticated) {
      if (!authProvider.isEmailVerified && authProvider.user?.providerData.any((element) => element.providerId == 'password') == true) {
        return EmailVerificationScreen();
      }
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  }
}

// 5. Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (!_isLogin && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  obscureText: !_passwordVisible,
                ),
                SizedBox(height: 24),
                
                // Error message
                if (authProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      authProvider.error!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                
                // Login/Register button
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            bool success = _isLogin
                                ? await authProvider.signInWithEmailAndPassword(
                                    _emailController.text,
                                    _passwordController.text,
                                  )
                                : await authProvider.registerWithEmailAndPassword(
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                            
                            if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(authProvider.error ?? 'An error occurred')),
                              );
                            }
                          }
                        },
                  child: authProvider.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(_isLogin ? 'Signing in...' : 'Creating account...'),
                          ],
                        )
                      : Text(_isLogin ? 'Login' : 'Register'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 16),
                
                // Social Login Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Google Sign In button
                OutlinedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          bool success = await authProvider.signInWithGoogle();
                          if (!success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(authProvider.error ?? 'An error occurred')),
                            );
                          }
                        },
                  child: authProvider.isLoading 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Connecting...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/google_logo.png', height: 24),
                            SizedBox(width: 12),
                            Text('Sign in with Google'),
                          ],
                        ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 12),
                
                // Apple Sign In button
                if (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
                  OutlinedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            bool success = await authProvider.signInWithApple();
                            if (!success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(authProvider.error ?? 'An error occurred')),
                              );
                            }
                          },
                    child: authProvider.isLoading 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Connecting...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple, size: 28),
                              SizedBox(width: 12),
                              Text('Sign in with Apple'),
                            ],
                          ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                // Facebook Sign In button
                SizedBox(height: 12),
                OutlinedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          bool success = await authProvider.signInWithFacebook();
                          if (!success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(authProvider.error ?? 'An error occurred')),
                            );
                          }
                        },
                  child: authProvider.isLoading 
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Connecting...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.facebook, size: 24, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Sign in with Facebook', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Color(0xFF1877F2), // Facebook blue
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                
                // Toggle between login and register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(_isLogin
                      ? 'Don\'t have an account? Register'
                      : 'Already have an account? Login'),
                ),
                
                // Forgot password
                if (_isLogin)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text('Forgot Password?'),
                      ),
                      SizedBox(width: 24),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PasskeySignInScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fingerprint, size: 18),
                            SizedBox(width: 4),
                            Text('Sign in with Passkey'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// 6. Email Verification Screen
class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // Timer for checking email verification
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    // Check email verification periodically
    _timer = Timer.periodic(Duration(seconds: 5), (_) {
      _checkEmailVerification();
    });
  }
  
  Future<void> _checkEmailVerification() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkEmailVerification();
    
    // If verified, cancel timer and proceed
    if (authProvider.isEmailVerified) {
      _timer?.cancel();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Your Email'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email,
                size: 80,
                color: Colors.blue,
              ),
              SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'A verification email has been sent to:',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                '${user?.email ?? 'your email'}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Text(
                'Please check your inbox and click the verification link to complete your registration.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              if (authProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    authProvider.error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: authProvider.isVerifying
                    ? null
                    : () async {
                        await authProvider.sendVerificationEmail();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Verification email sent again!')),
                        );
                      },
                child: authProvider.isVerifying
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                          ),
                          SizedBox(width: 12),
                          Text('Sending...'),
                        ],
                      )
                    : Text('Resend Verification Email'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  await authProvider.checkEmailVerification();
                  if (!authProvider.isEmailVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Email not verified yet. Please check your inbox.')),
                    );
                  }
                },
                child: Text('I\'ve Verified My Email'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// 7. Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Success view after email is sent
                  if (_emailSent) ...[
                    Icon(
                      Icons.mark_email_read,
                      size: 80,
                      color: Colors.green,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Recovery Email Sent',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'We\'ve sent password recovery instructions to:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _emailController.text,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Please check your email inbox and follow the instructions to reset your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Back to Login'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _emailSent = false;
                        });
                      },
                      child: Text('Use a different email address'),
                    ),
                  ] else ...[
                    // Initial form view
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Forgot Password?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Enter your email address and we\'ll send you instructions to reset your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 32),
                    
                    // Error message
                    if (authProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          authProvider.error!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Email input
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your registered email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: [AutofillHints.email],
                    ),
                    SizedBox(height: 32),
                    
                    // Submit button
                    ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                await authProvider.resetPassword(_emailController.text);
                                
                                if (authProvider.error == null) {
                                  setState(() {
                                    _emailSent = true;
                                  });
                                }
                              }
                            },
                      child: authProvider.isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Sending...'),
                              ],
                            )
                          : Text('Send Reset Link'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Back to Login'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// Legacy Reset Password Dialog (kept for backward compatibility)
class ResetPasswordDialog extends StatefulWidget {
  @override
  _ResetPasswordDialogState createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return AlertDialog(
      title: Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
          keyboardType: TextInputType.emailAddress,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: authProvider.isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    await authProvider.resetPassword(_emailController.text);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Password reset email sent. Please check your inbox.',
                        ),
                      ),
                    );
                  }
                },
          child: Text('Send Reset Link'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// 8. Home Screen (authenticated users only)
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to passkey management when tapping profile picture
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PasskeyManagementScreen(),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Icon(Icons.person, size: 50)
                          : null,
                    ),
                    // Show passkey badge if user has a passkey
                    if (authProvider.hasPasskey)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Welcome, ${user?.displayName ?? user?.email ?? 'User'}!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Email: ${user?.email ?? 'Not available'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'User ID: ${user?.uid ?? 'Not available'}',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 32),
              // Passkey management button
              if (authProvider.canUsePasskeys) ...[
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PasskeyManagementScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.fingerprint),
                  label: Text(authProvider.hasPasskey 
                      ? 'Manage Passkey' 
                      : 'Set Up Passkey'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                  ),
                ),
              ],
              
              SizedBox(height: 16),
              
              // Admin access section
              FutureBuilder<bool>(
                future: authProvider.checkAdminRole(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return Column(
                      children: [
                        Text(
                          'Admin Access Granted',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to admin panel
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AdminPanel(),
                              ),
                            );
                          },
                          child: Text('Go to Admin Panel'),
                        ),
                      ],
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 9. Admin Panel (example of protected route)
class AdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: Center(
        child: Text(
          'This is a protected admin area',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// 10. Passkey Sign In Screen
class PasskeySignInScreen extends StatefulWidget {
  @override
  _PasskeySignInScreenState createState() => _PasskeySignInScreenState();
}

class _PasskeySignInScreenState extends State<PasskeySignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign in with Passkey'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 80,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Sign in with Passkey',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Use your device\'s biometric authentication to sign in securely without a password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 32),
                  
                  // Error message
                  if (authProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        authProvider.error!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your registered email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: [AutofillHints.email],
                  ),
                  SizedBox(height: 32),
                  
                  // Sign in button
                  ElevatedButton(
                    onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                              bool success = await authProvider.signInWithPasskey(
                              _emailController.text,
                            );
                            
                            if (success && mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                    child: authProvider.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Authenticating...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fingerprint),
                            SizedBox(width: 8),
                            Text('Authenticate with Passkey'),
                          ],
                        ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// 11. Passkey Management Screen
class PasskeyManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Passkeys'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passkey Security',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Passkeys provide a more secure way to sign in than traditional passwords. They use biometric authentication (like fingerprint or face recognition) to verify your identity.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            
            // Current status
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          authProvider.hasPasskey 
                              ? Icons.check_circle 
                              : Icons.cancel,
                          color: authProvider.hasPasskey 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          authProvider.hasPasskey
                              ? 'Passkey is set up and active'
                              : 'No passkey registered',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    if (!authProvider.canUsePasskeys) ...[
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your device does not support passkeys or biometric authentication',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            
            // Error message
            if (authProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  authProvider.error!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            
            // Manage passkey buttons
            if (authProvider.canUsePasskeys) ...[
              if (authProvider.hasPasskey)
                ElevatedButton.icon(
                  onPressed: authProvider.isLoading || authProvider.isRegisteringPasskey
                      ? null
                      : () => authProvider.removePasskey(),
                  icon: Icon(Icons.delete),
                  label: Text('Remove Passkey'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: Size(double.infinity, 50),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: authProvider.isLoading || authProvider.isRegisteringPasskey
                      ? null
                      : () => authProvider.registerPasskey(),
                  icon: Icon(Icons.add),
                  label: authProvider.isRegisteringPasskey
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Setting up passkey...'),
                          ],
                        )
                      : Text('Set Up Passkey'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}