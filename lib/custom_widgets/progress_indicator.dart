import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutProgress extends StatefulWidget {
  final int currentStep;
  final int previousStep;

  const CheckoutProgress({
    Key? key,
    required this.currentStep,
    this.previousStep = 0,
  }) : super(key: key);

  @override
  State<CheckoutProgress> createState() => _CheckoutProgressState();
}

class _CheckoutProgressState extends State<CheckoutProgress>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _progressController;

  // Add separate animation controllers for step color transitions
  late AnimationController _step1ColorController;
  late AnimationController _step2ColorController;
  late AnimationController _step3ColorController;

  late Animation<double> _checkAnimation;
  late Animation<double> _progressAnimation;

  // Color animations for steps
  late Animation<double> _step1ColorAnimation;
  late Animation<double> _step2ColorAnimation;
  late Animation<double> _step3ColorAnimation;

  double _progressStart = 0.0;
  double _progressEnd = 0.0;

  bool _showCheck = false;
  bool _skipFirstStepAnimation = false;

  @override
  void initState() {
    super.initState();

    _progressStart = _calculateProgress(widget.previousStep);
    _progressEnd = _calculateProgress(widget.currentStep);

    // Skip first step animation only when going directly to payment screen from cart
    _skipFirstStepAnimation =
        widget.currentStep == 3 && widget.previousStep <= 1;

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );

    // Initialize color transition controllers
    _step1ColorController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _step2ColorController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _step3ColorController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _checkAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_checkController);
    _progressAnimation = Tween<double>(begin: _progressStart, end: _progressEnd)
        .animate(CurvedAnimation(
            parent: _progressController, curve: Curves.easeInOut));

    // Color animations
    _step1ColorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _step1ColorController, curve: Curves.easeOut));
    _step2ColorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _step2ColorController, curve: Curves.easeOut));
    _step3ColorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _step3ColorController, curve: Curves.easeOut));

    // Initialize color states based on current step
    _initializeColorStates();

    // Start the animation sequence
    _startAnimation();
  }

  void _initializeColorStates() {
    // Set initial color states based on current and previous steps
    if (widget.currentStep >= 1) {
      _step1ColorController.value = 1.0;
    }

    if (widget.currentStep >= 2 && widget.previousStep >= 2) {
      _step2ColorController.value = 1.0;
    }

    if (widget.currentStep >= 3 && widget.previousStep >= 3) {
      _step3ColorController.value = 1.0;
    }
  }

  Future<void> _startAnimation() async {
    // For direct navigation to payment from cart, skip first step checkmark animation
    if (_skipFirstStepAnimation &&
        widget.currentStep == 3 &&
        widget.previousStep <= 1) {
      // Skip animation for first step
      _checkController.value = 1.0;
    } else {
      // Normal animation flow
      await _checkController.forward();
    }

    // Animate progress bar
    await _progressController.forward();

    // Animate color transitions after progress bar reaches each step
    if (widget.currentStep >= 1 && widget.previousStep < 1) {
      await _step1ColorController.forward();
    }

    if (widget.currentStep >= 2 && widget.previousStep < 2) {
      await _step2ColorController.forward();
    }
    if (widget.currentStep >= 3 && widget.previousStep < 3) {
      await _step3ColorController.forward();
    }

    // if (widget.currentStep == 3 && widget.previousStep == 2) {
    //   // Set a short delay to make the checkmark transition visible before progress animation
    //   await Future.delayed(const Duration(milliseconds: 1600));
    // }

    if (widget.currentStep >= 3 && widget.previousStep < 3) {
      // For transitions to payment screen from address, ensure address step checkmark
      // is clearly visible before color transition
      if (widget.previousStep == 2) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await _step3ColorController.forward();
    }

    setState(() {
      _showCheck = true; // Update state after animations complete
    });
  }

  double _calculateProgress(int step) {
    return (step - 1) / 2; // 0.0, 0.5, 1.0
  }

  @override
  void didUpdateWidget(covariant CheckoutProgress oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentStep != widget.currentStep) {
      _progressStart = _calculateProgress(oldWidget.currentStep);
      _progressEnd = _calculateProgress(widget.currentStep);

      // Skip first step animation only when going directly to payment screen from cart
      _skipFirstStepAnimation =
          widget.currentStep == 3 && widget.previousStep <= 1;

      _checkController.reset();
      _progressController.reset();

      // Only reset color controllers for steps that need to transition
      if (oldWidget.currentStep < 1 && widget.currentStep >= 1) {
        _step1ColorController.reset();
      }
      if (oldWidget.currentStep < 2 && widget.currentStep >= 2) {
        _step2ColorController.reset();
      }
      if (oldWidget.currentStep < 3 && widget.currentStep >= 3) {
        _step3ColorController.reset();
      }

      _progressAnimation = Tween<double>(
        begin: _progressStart,
        end: _progressEnd,
      ).animate(CurvedAnimation(
          parent: _progressController, curve: Curves.easeInOut));

      _showCheck = false;
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _progressController.dispose();
    _step1ColorController.dispose();
    _step2ColorController.dispose();
    _step3ColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(10,6,8,6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Progress bar
          Positioned(
            left: 22,
            right: 55,
            top: 14,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  color: const Color(0xFF101D42),
                  backgroundColor: Colors.grey[200],
                  minHeight: 1.5,
                );
              },
            ),
          ),
          // Step indicators
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildStepItem(1, ' Cart ', _step1ColorAnimation),
                ),
                _buildStepItem(2, 'Address', _step2ColorAnimation),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildStepItem(3, 'Payment', _step3ColorAnimation),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
      int step, String title, Animation<double> colorAnimation) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_checkAnimation, _progressAnimation, colorAnimation]),
      builder: (context, child) {
        // Use the dedicated color animation instead of progress-based fill percent
        double fillPercent = step == 1 ? 1.0 : colorAnimation.value;

        bool isCompleted = _progressAnimation.value >= (step / 2) &&
            _progressController.isCompleted;

        // Determine when to show the checkmark for each step
        bool shouldShowCheck = false;

        // Navigation to step 2 (Address) - show step 1 checkmark after animation completes
        if (step == 1 && widget.currentStep == 2) {
          shouldShowCheck = _checkController.isCompleted;
        }
        // Navigation to step 3 (Payment) - step 1 always shows checkmark
        else if (step == 1 && widget.currentStep == 3) {
          shouldShowCheck = true;
        }
        // Navigation to step 3 (Payment) - show step 2 checkmark after animation completes
        else if (step == 2 && widget.currentStep == 3) {
          shouldShowCheck = _checkController.isCompleted;
        }
        // Other completed steps
        else if (isCompleted ||
            (widget.currentStep > step && _progressController.isCompleted)) {
          shouldShowCheck = true;
        }

        Color bgColor = Color.lerp(
          Colors.grey.shade100,
          const Color(0xFF101D42),
          fillPercent,
        )!;

        Color borderColor = Color.lerp(
          Colors.grey.shade300,
          const Color(0xFF101D42),
          fillPercent,
        )!;

        Color textColor =
            fillPercent > 0.5 ? Colors.white : Colors.grey.shade500;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    // Skip animation for step 1 when going directly to payment
                    if (step == 1 &&
                        _skipFirstStepAnimation &&
                        widget.currentStep == 3) {
                      return child;
                    }
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: shouldShowCheck
                      ? const Icon(
                          Icons.check,
                          key: ValueKey('check'),
                          color: Colors.white,
                          size: 15,
                        )
                      : Text(
                          step.toString(),
                          key: ValueKey('number'),
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: fillPercent > 0.5 ? Colors.black : Colors.grey.shade500,
                fontSize: 12,
                fontWeight:
                    fillPercent > 0.5 ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        );
      },
    );
  }
}
