class SupportMacro {
  final String name;
  final String reply;        // inserted into composer
  final String? statusAfter; // e.g. 'resolved' | 'closed'
  final List<String> addTags;
  final bool assignToMe;

  const SupportMacro({
    required this.name,
    required this.reply,
    this.statusAfter,
    this.addTags = const [],
    this.assignToMe = false,
  });
}

const kSupportMacros = <SupportMacro>[
  SupportMacro(
    name: 'Welcome + tips',
    reply: 'Thanks for reaching out! Here are a few quick tips...',
    addTags: ['greeting'],
  ),
  SupportMacro(
    name: 'Billing — resolved',
    reply: 'We adjusted your billing and you should be all set now.',
    statusAfter: 'resolved',
    addTags: ['billing'],
    assignToMe: true,
  ),
  SupportMacro(
    name: 'Bug acknowledged',
    reply: 'We reproduced the issue and are working on a fix. I\'ll update you soon.',
    addTags: ['bug'],
  ),
  SupportMacro(
    name: 'Close — no response',
    reply: 'Closing this ticket for now. If the issue persists, just reply to reopen.',
    statusAfter: 'closed',
  ),
];
