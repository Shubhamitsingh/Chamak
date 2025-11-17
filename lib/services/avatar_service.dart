class AvatarService {
  // Provider: Simple cartoon-style human avatars (like your image)
  // Deterministic per user using uid as seed
  static String generateAvatarUrl({required String userId, String? gender}) {
    final safeSeed = Uri.encodeComponent(userId);
    
    // DiceBear 'big-smile' style - Simple, clean, flat cartoon humans
    // Features: Round faces, simple eyes, smiles, diverse skin tones
    // Similar to the avatar you showed - friendly, simple, clean
    // Supports both male and female avatars
    return 'https://api.dicebear.com/7.x/big-smile/png?seed=$safeSeed&size=300&backgroundColor=b6e3f4';
    
    // Alternative: 'avataaars' - Classic cartoon style (Slack-like)
    // return 'https://api.dicebear.com/7.x/avataaars/png?seed=$safeSeed&size=300';
    
    // Alternative: 'fun-emoji' - Simple emoji-style faces
    // return 'https://api.dicebear.com/7.x/fun-emoji/png?seed=$safeSeed&size=300';
  }
}



