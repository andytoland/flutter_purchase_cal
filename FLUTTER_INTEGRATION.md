# Flutter Integration Walkthrough

I have prepared the backend and documentation to help you build a Flutter app for `purchase-calc`.

## Changes Made

### Backend: Mobile Login Endpoint
I added a new POST endpoint at `/login/mobile` that verifies a Google ID Token. This allows your Flutter app to authenticate by:
1.  Getting an `idToken` from Google Sign-In in Flutter.
2.  Sending that token via POST to `/login/mobile`.
3.  Receiving the backend JWT in the response body.

```typescript
// Example POST /login/mobile body
{
  "idToken": "your-google-id-token"
}
```

### Backend: Bearer Token Support
I updated the [jwt.guard.ts](file:///c:/Users/antti/Kehitys/oma/purchase-calc/src/auth/jwt.guard.ts) to support the `Authorization: Bearer <token>` header. This is the standard way for mobile apps to authenticate with APIs, as managing cookies in mobile environments can be cumbersome.

```typescript
// Updated logic in JwtGuard
let token: string = request.cookies['jwt'];

if (!token) {
  const authHeader = request.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ')) {
    token = authHeader.substring(7);
  }
}
```

## Next Steps for You

1. **Initialize Flutter**: Run `flutter create your_app_name`.
2. **Add Dependencies**: 
   ```yaml
   dependencies:
     dio: ^5.3.3
     google_sign_in: ^6.1.6
     flutter_secure_storage: ^9.0.0
   ```
3. **Connectivity**: If testing locally with an Android emulator, use `http://10.0.2.2:8080` as the base URL to reach your host machine.
