

/// Referral code model
class ReferralCode {
  final String userId;
  final String code;
  final String status; // 'active' or 'disabled'
  final DateTime createdAt;

  ReferralCode({
    required this.userId,
    required this.code,
    required this.status,
    required this.createdAt,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      userId: json['user_id'] as String,
      code: json['code'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'code': code,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
}

/// Referral model
class Referral {
  final String id;
  final String referrerId;
  final String refereeId;
  final String code;
  final String? source;
  final String? milestone; // 'checklist' or 'payment'
  final DateTime? rewardedAt;
  final List<String> rewardType;
  final Map<String, dynamic> rewardValues;
  final bool fraudFlag;
  final DateTime createdAt;

  Referral({
    required this.id,
    required this.referrerId,
    required this.refereeId,
    required this.code,
    this.source,
    this.milestone,
    this.rewardedAt,
    required this.rewardType,
    required this.rewardValues,
    required this.fraudFlag,
    required this.createdAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      referrerId: json['referrer_id'] as String,
      refereeId: json['referee_id'] as String,
      code: json['code'] as String,
      source: json['source'] as String?,
      milestone: json['milestone'] as String?,
      rewardedAt: json['rewarded_at'] != null 
          ? DateTime.parse(json['rewarded_at'] as String)
          : null,
      rewardType: List<String>.from(json['reward_type'] ?? []),
      rewardValues: json['reward_values'] as Map<String, dynamic>? ?? {},
      fraudFlag: json['fraud_flag'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrer_id': referrerId,
      'referee_id': refereeId,
      'code': code,
      'source': source,
      'milestone': milestone,
      'rewarded_at': rewardedAt?.toIso8601String(),
      'reward_type': rewardType,
      'reward_values': rewardValues,
      'fraud_flag': fraudFlag,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isRewarded => rewardedAt != null;
  bool get isChecklistMilestone => milestone == 'checklist';
  bool get isPaymentMilestone => milestone == 'payment';
  bool get isQueued => rewardValues['queue_month'] != null;
}

/// Affiliate link model
class AffiliateLink {
  final String id;
  final String coachId;
  final String slug;
  final double bountyUsd;
  final String status; // 'active' or 'disabled'
  final DateTime createdAt;

  AffiliateLink({
    required this.id,
    required this.coachId,
    required this.slug,
    required this.bountyUsd,
    required this.status,
    required this.createdAt,
  });

  factory AffiliateLink.fromJson(Map<String, dynamic> json) {
    return AffiliateLink(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      slug: json['slug'] as String,
      bountyUsd: (json['bounty_usd'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'slug': slug,
      'bounty_usd': bountyUsd,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  String get shareUrl => 'https://your-app.com/affiliate/$slug';
}

/// Affiliate conversion model
class AffiliateConversion {
  final String id;
  final String linkId;
  final String clientId;
  final double amount;
  final String status; // 'pending', 'approved', 'paid'
  final String? payoutBatchId;
  final DateTime createdAt;

  AffiliateConversion({
    required this.id,
    required this.linkId,
    required this.clientId,
    required this.amount,
    required this.status,
    this.payoutBatchId,
    required this.createdAt,
  });

  factory AffiliateConversion.fromJson(Map<String, dynamic> json) {
    return AffiliateConversion(
      id: json['id'] as String,
      linkId: json['link_id'] as String,
      clientId: json['client_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      payoutBatchId: json['payout_batch_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'link_id': linkId,
      'client_id': clientId,
      'amount': amount,
      'status': status,
      'payout_batch_id': payoutBatchId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isPaid => status == 'paid';
}

/// Affiliate payout batch model (admin managed)
class AffiliatePayoutBatch {
  final String id;
  final String createdBy;
  final String? note;
  final DateTime createdAt;

  AffiliatePayoutBatch({
    required this.id,
    required this.createdBy,
    this.note,
    required this.createdAt,
  });

  factory AffiliatePayoutBatch.fromJson(Map<String, dynamic> json) {
    return AffiliatePayoutBatch(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Monthly referral cap view model
class ReferralMonthlyCap {
  final String referrerId;
  final DateTime month;
  final int referralCount;

  ReferralMonthlyCap({
    required this.referrerId,
    required this.month,
    required this.referralCount,
  });

  factory ReferralMonthlyCap.fromJson(Map<String, dynamic> json) {
    return ReferralMonthlyCap(
      referrerId: json['referrer_id'] as String,
      month: DateTime.parse(json['month'] as String),
      referralCount: json['referral_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referrer_id': referrerId,
      'month': month.toIso8601String(),
      'referral_count': referralCount,
    };
  }

  bool get isAtCap => referralCount >= 5;
  int get remaining => 5 - referralCount;
}
