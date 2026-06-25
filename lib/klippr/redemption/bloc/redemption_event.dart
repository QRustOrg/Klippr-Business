sealed class RedemptionEvent {
  const RedemptionEvent();
}

class LookupToken extends RedemptionEvent {
  const LookupToken({required this.uniqueToken});
  final String uniqueToken;
}

class ConfirmToken extends RedemptionEvent {
  const ConfirmToken({required this.uniqueToken});
  final String uniqueToken;
}

class LoadHistory extends RedemptionEvent {
  const LoadHistory({required this.promotionId});
  final String promotionId;
}

class ResetLookup extends RedemptionEvent {
  const ResetLookup();
}

class RedemptionFlagsConsumed extends RedemptionEvent {
  const RedemptionFlagsConsumed();
}
