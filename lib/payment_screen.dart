import 'package:flutter/material.dart';
import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/api_service.dart';
import 'success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String stationId;
  const PaymentScreen({super.key, required this.stationId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _statusMessage;
  String? _authToken;

  static const String merchantIdentifier = 'merchant.com.YOUR_ID';

  @override
  void initState() {
    super.initState();
    _initializeAccount();
  }

  Future<void> _initializeAccount() async {
    setState(() => _isLoading = true);
    try {
      final token = await _apiService.generateAccountToken();
      setState(() => _authToken = token);
    } catch (e) {
      setState(() => _statusMessage = 'Error creating account: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startApplePayFlow() async {
    final token = _authToken;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final clientToken =
          await _apiService.generateBraintreeClientToken(authToken: token);

      final dropInReq = BraintreeDropInRequest(
        clientToken: clientToken,
        collectDeviceData: true,
        cardEnabled: false,
        paypalRequest: null,
        googlePaymentRequest: null,
        applePayRequest: BraintreeApplePayRequest(
          paymentSummaryItems: [
            ApplePaySummaryItem(
              label: 'Monthly Subscription',
              amount: 4.99,
              type: ApplePaySummaryItemType.final_,
            ),
          ],
          displayName: 'Monthly Subscription',
          currencyCode: 'USD',
          countryCode: 'US',
          merchantIdentifier: merchantIdentifier,
          supportedNetworks: const [
            ApplePaySupportedNetworks.visa,
            ApplePaySupportedNetworks.masterCard,
            ApplePaySupportedNetworks.amex,
          ],
        ),
      );

      final result = await BraintreeDropIn.start(dropInReq);
      if (result == null) {
        setState(() => _statusMessage = 'Payment canceled');
        return;
      }

      final nonce = result.paymentMethodNonce.nonce;
      final paymentToken = await _apiService.addPaymentMethod(
        authToken: token,
        paymentNonce: nonce,
        paymentType: 'APPLE_PAY',
        description: 'Apple Pay (Drop-In)',
      );

      await _apiService.createSubscriptionTransaction(
        authToken: token,
        disableWelcomeDiscount: false,
        welcomeDiscount: 10,
        paymentToken: paymentToken,
        planId: 'tss2',
      );

      await _apiService.rentPowerBank(
        authToken: token,
        stationId: widget.stationId,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(stationId: widget.stationId),
        ),
      );
    } catch (e) {
      setState(() => _statusMessage = 'Payment failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startCardFlow() async {
    final token = _authToken;
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final clientToken =
          await _apiService.generateBraintreeClientToken(authToken: token);

      final request = BraintreeDropInRequest(
        clientToken: clientToken,
        collectDeviceData: true,
        cardEnabled: true,
        paypalRequest: null,
        googlePaymentRequest: null,
        applePayRequest: null,
        amount: '4.99',
      );

      final result = await BraintreeDropIn.start(request);
      if (result == null) {
        setState(() => _statusMessage = 'Payment canceled');
        return;
      }

      final nonce = result.paymentMethodNonce.nonce;
      final paymentToken = await _apiService.addPaymentMethod(
        authToken: token,
        paymentNonce: nonce,
        paymentType: 'CARD',
        description: 'Card (Drop-In)',
      );

      await _apiService.createSubscriptionTransaction(
        authToken: token,
        disableWelcomeDiscount: false,
        welcomeDiscount: 10,
        paymentToken: paymentToken,
        planId: 'tss2',
      );

      await _apiService.rentPowerBank(
        authToken: token,
        stationId: widget.stationId,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(stationId: widget.stationId),
        ),
      );
    } catch (e) {
      setState(() => _statusMessage = 'Payment failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF0A0A0A);
    const muted = Color(0xFF9B9B9B);
    const divider = Color(0xFFE9E9EA);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),
                  Text(
                    'Monthly Subscription',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 30.sp, // адаптивный заголовок
                      fontWeight: FontWeight.w400,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 2.5.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$4.99',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        '\$9.99',
                        style: TextStyle(
                          fontSize: 17.sp,
                          color: muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  Text(
                    'First month only',
                    style: TextStyle(fontSize: 14.sp, color: muted),
                  ),
                  SizedBox(height: 2.5.h),
                  const Divider(color: divider, thickness: 1),
                  SizedBox(height: 2.5.h),
                  GestureDetector(
                    onTap: _startApplePayFlow,
                    child: Container(
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(3.5.h),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ' Pay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.5.h),
                  const Divider(color: divider, thickness: 1),
                  InkWell(
                    onTap: _startCardFlow,
                    borderRadius: BorderRadius.circular(2.h),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.2.h),
                      child: Row(
                        children: [
                          SizedBox(width: 0.5.w),
                          Icon(Icons.credit_card,
                              size: 3.2.h, color: textPrimary),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              'Debit or credit card',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16.5.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              size: 2.h, color: textPrimary),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: divider, thickness: 1),
                  SizedBox(height: 25.h),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 1.w,
                      children: [
                        Text(
                          'Nothing happened?',
                          style: TextStyle(
                            color: const Color(0xFF5F5F5F),
                            fontSize: 14.sp,
                            letterSpacing: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse('mailto:support@example.com');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Text(
                            'Contact support',
                            style: TextStyle(
                              color: const Color(0xFF5F5F5F),
                              fontSize: 14.sp,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1.2,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.75),
                child: const Center(child: CircularProgressIndicator()),
              ),
            if (_statusMessage != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(2.h),
                    child: Container(
                      padding: EdgeInsets.all(2.h),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(2.h),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              _statusMessage ?? '',
                              style:
                                  TextStyle(color: Colors.red, fontSize: 14.sp),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _statusMessage = null),
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
