/// One stage of the booking timeline from the specification:
/// Booking Created, Payment Received, Hotel Confirmed, Flights Confirmed,
/// Travel Documents Issued, Ready to Travel, Completed.
class TimelineStep {
  const TimelineStep(this.label, this.done);

  final String label;
  final bool done;
}

/// How far along a status is. Cancelled is -1 (no progress shown).
int statusRank(String status) {
  switch (status) {
    case 'Pending':
      return 0;
    case 'Processing':
      return 1;
    case 'AwaitingPayment':
      return 2;
    case 'PaymentReceived':
      return 3;
    case 'Confirmed':
      return 4;
    case 'DocumentsPending':
      return 5;
    case 'DocumentsIssued':
      return 6;
    case 'ReadyToTravel':
      return 7;
    case 'TravelCompleted':
    case 'Closed':
      return 8;
    default:
      return -1;
  }
}

const List<String> _labels = <String>[
  'Booking Created',
  'Payment Received',
  'Hotel Confirmed',
  'Flights Confirmed',
  'Travel Documents Issued',
  'Ready to Travel',
  'Completed',
];

/// The rank a booking must reach before each step counts as done.
const List<int> _thresholds = <int>[0, 3, 4, 4, 6, 7, 8];

List<TimelineStep> buildTimeline(String status) {
  final rank = statusRank(status);
  return List<TimelineStep>.generate(
    _labels.length,
    (index) => TimelineStep(_labels[index], rank >= _thresholds[index]),
  );
}
