import 'api_client.dart';

/// A distinct type from ApiClient so Provider can hold a second, independent
/// client for staff sessions without clashing with the customer ApiClient.
/// Customers and staff can be signed in on the same device at the same time,
/// each with their own token, because these are two separate ApiClient instances.
class StaffApiClient {
  StaffApiClient(this.api);

  final ApiClient api;
}
