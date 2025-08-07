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
        actions: [
          IconButton(
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
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient effect
          Container(
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
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Message history
                Expanded(
                  child: BlocBuilder<VoiceAssistantCubit, VoiceAssistantState>(
                    buildWhen: (previous, current) =>
                        previous.messages != current.messages,
                    builder: (context, state) {
                      return CustomScrollView(
                        slivers: [
                          // Empty state or messages
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
                                    final isUser =
                                        message.author == MessageAuthor.user;
                                    return Align(
                                      alignment: isUser
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.75,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? Colors.purple
                                                  .withValues(alpha: 0.2)
                                              : Colors.white
                                                  .withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isUser
                                                ? Colors.purple
                                                    .withValues(alpha: 0.3)
                                                : Colors.white
                                                    .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        child: Text(
                                          message.text,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize: 16,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ).animate().fadeIn(duration: 300.ms).slideX(
                                          begin: isUser ? 0.1 : -0.1,
                                          end: 0,
                                          duration: 300.ms,
                                          curve: Curves.easeOutCubic,
                                        );
                                  },
                                  childCount: state.messages.length,
                                ),
                              ),
                            ),
                          // Extra space at bottom for mic button
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 180),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Bottom controls (mic button and status)
          Positioned(
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
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Listening status text
                    BlocBuilder<VoiceAssistantCubit, VoiceAssistantState>(
                      buildWhen: (previous, current) =>
                          previous.listeningToSpeechStatus !=
                          current.listeningToSpeechStatus,
                      builder: (context, state) {
                        final isListening = state.listeningToSpeechStatus ==
                            ListeningToSpeechStatus.listening;
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
                    ),
                    const SizedBox(height: 16),
                    // Microphone button with ripple effect
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ripple effect circles
                        BlocBuilder<VoiceAssistantCubit, VoiceAssistantState>(
                          buildWhen: (previous, current) =>
                              previous.listeningToSpeechStatus !=
                              current.listeningToSpeechStatus,
                          builder: (context, state) {
                            final isListening = state.listeningToSpeechStatus ==
                                ListeningToSpeechStatus.listening;
                            return SizedBox(
                              width: 200,
                              height: 200,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (isListening) ...[
                                    _buildRippleCircle(160, 0),
                                    _buildRippleCircle(140, 200),
                                    _buildRippleCircle(120, 400),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        // Microphone button
                        BlocBuilder<VoiceAssistantCubit, VoiceAssistantState>(
                          builder: (context, state) {
                            final isListening = state.listeningToSpeechStatus ==
                                ListeningToSpeechStatus.listening;
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
                                      context
                                          .read<VoiceAssistantCubit>()
                                          .stopListening();
                                    } else {
                                      context
                                          .read<VoiceAssistantCubit>()
                                          .startListening();
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRippleCircle(double size, int delay) {
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
