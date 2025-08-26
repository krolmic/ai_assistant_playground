import 'package:ai_assistant_1/settings/settings.dart';
import 'package:ai_assistant_1/voice_assistant/models/models.dart';
import 'package:ai_assistant_1/voice_assistant/voice_assistant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VoiceAssistantPage extends StatelessWidget {
  const VoiceAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VoiceAssistantCubit(
        speechToTextRepository: context.read(),
        textResponsesRepository: context.read(),
      ),
      child: const VoiceAssistantView(),
    );
  }
}

class VoiceAssistantView extends StatelessWidget {
  const VoiceAssistantView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          _SettingsButton(),
        ],
      ),
      body: Stack(
        children: const [
          _BackgroundGradient(),
          SafeArea(
            child: Column(
              children: [
                _MessagesView(),
              ],
            ),
          ),
          _BottomControls(),
        ],
      ),
    );
  }

  static Widget _buildRippleCircle(double size, int delay) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 2000.ms,
          delay: delay.ms,
        )
        .fadeOut(
          begin: 0.5,
          duration: 2000.ms,
          delay: delay.ms,
        );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.settings,
        color: Colors.white,
      ),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (context) => const SettingsDialog(),
        );
      },
    );
  }
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.5,
          colors: [
            Colors.purple.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<VoiceAssistantCubit, VoiceAssistantState>(
        buildWhen: (previous, current) => previous.messages != current.messages,
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              if (state.messages.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Start a conversation',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final message = state.messages[index];
                        final isUser = message.author == MessageAuthor.user;
                        return _MessageBubble(
                          text: message.text,
                          isUser: isUser,
                        );
                      },
                      childCount: state.messages.length,
                    ),
                  ),
                ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 180),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.purple.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser
                ? Colors.purple.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(
          begin: isUser ? 0.1 : -0.1,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A0A).withValues(alpha: 0),
              const Color(0xFF0A0A0A).withValues(alpha: 0.8),
              const Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: const SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ListeningStatusText(),
              SizedBox(height: 16),
              _MicWithRipples(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListeningStatusText extends StatelessWidget {
  const _ListeningStatusText();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceAssistantCubit, VoiceAssistantState>(
      buildWhen: (previous, current) =>
          previous.listeningToSpeechStatus != current.listeningToSpeechStatus,
      builder: (context, state) {
        final isListening =
            state.listeningToSpeechStatus == ListeningToSpeechStatus.listening;
        return Text(
          isListening ? 'Listening...' : 'Tap to speak',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        )
            .animate(target: isListening ? 1 : 0)
            .fadeIn(duration: 300.ms)
            .then()
            .shimmer(
              duration: 1500.ms,
              color: Colors.purple.withValues(alpha: 0.3),
            );
      },
    );
  }
}

class _MicWithRipples extends StatelessWidget {
  const _MicWithRipples();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        _RippleCircles(),
        _MicButton(),
      ],
    );
  }
}

class _RippleCircles extends StatelessWidget {
  const _RippleCircles();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceAssistantCubit, VoiceAssistantState>(
      buildWhen: (previous, current) =>
          previous.listeningToSpeechStatus != current.listeningToSpeechStatus,
      builder: (context, state) {
        final isListening =
            state.listeningToSpeechStatus == ListeningToSpeechStatus.listening;
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isListening) ...[
                VoiceAssistantView._buildRippleCircle(160, 0),
                VoiceAssistantView._buildRippleCircle(140, 200),
                VoiceAssistantView._buildRippleCircle(120, 400),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceAssistantCubit, VoiceAssistantState>(
      builder: (context, state) {
        final isListening =
            state.listeningToSpeechStatus == ListeningToSpeechStatus.listening;
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withValues(alpha: 0.4),
                Colors.purple.withValues(alpha: 0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () {
                if (isListening) {
                  context.read<VoiceAssistantCubit>().stopListening();
                } else {
                  context.read<VoiceAssistantCubit>().startListening();
                }
              },
              child: Icon(
                isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ).animate(target: isListening ? 1 : 0).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 300.ms,
            );
      },
    );
  }
}
