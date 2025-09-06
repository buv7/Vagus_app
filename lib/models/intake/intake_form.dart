class IntakeForm {
  final String id;
  final String coachId;
  final Map<String, dynamic> schema;
  final DateTime updatedAt;

  const IntakeForm({
    required this.id,
    required this.coachId,
    required this.schema,
    required this.updatedAt,
  });

  factory IntakeForm.fromMap(Map<String, dynamic> map) {
    return IntakeForm(
      id: map['id']?.toString() ?? '',
      coachId: map['coach_id']?.toString() ?? '',
      schema: map['schema'] as Map<String, dynamic>? ?? {},
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'schema': schema,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  List<FormQuestion> get questions {
    final questionsList = schema['questions'] as List<dynamic>? ?? [];
    return questionsList.map((q) => FormQuestion.fromMap(q as Map<String, dynamic>)).toList();
  }

  bool get hasMandatoryAllergyQuestions {
    final questions = this.questions;
    return questions.any((q) => q.isMandatoryAllergyQuestion);
  }
}

class FormQuestion {
  final String id;
  final String type;
  final String title;
  final String? description;
  final bool required;
  final Map<String, dynamic> options;
  final int order;

  const FormQuestion({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.required,
    required this.options,
    required this.order,
  });

  factory FormQuestion.fromMap(Map<String, dynamic> map) {
    return FormQuestion(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'text',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      required: map['required'] as bool? ?? false,
      options: map['options'] as Map<String, dynamic>? ?? {},
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'required': required,
      'options': options,
      'order': order,
    };
  }

  bool get isMandatoryAllergyQuestion {
    final titleLower = title.toLowerCase();
    return titleLower.contains('allerg') && required;
  }

  List<String> get choiceOptions {
    return (options['choices'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  }
}

class IntakeResponse {
  final String id;
  final String formId;
  final String clientId;
  final Map<String, dynamic> answers;
  final DateTime createdAt;

  const IntakeResponse({
    required this.id,
    required this.formId,
    required this.clientId,
    required this.answers,
    required this.createdAt,
  });

  factory IntakeResponse.fromMap(Map<String, dynamic> map) {
    return IntakeResponse(
      id: map['id']?.toString() ?? '',
      formId: map['form_id']?.toString() ?? '',
      clientId: map['client_id']?.toString() ?? '',
      answers: map['answers'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'form_id': formId,
      'client_id': clientId,
      'answers': answers,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String? getAnswer(String questionId) {
    return answers[questionId]?.toString();
  }

  List<String> getFoodAllergies() {
    final allergies = <String>[];
    for (final entry in answers.entries) {
      final value = entry.value?.toString().toLowerCase() ?? '';
      if (value.contains('allerg') && value.contains('food')) {
        // Extract food allergies from the answer
        final parts = value.split(',');
        for (final part in parts) {
          final trimmed = part.trim();
          if (trimmed.isNotEmpty && !trimmed.contains('no') && !trimmed.contains('none')) {
            allergies.add(trimmed);
          }
        }
      }
    }
    return allergies;
  }

  List<String> getSubstanceAllergies() {
    final allergies = <String>[];
    for (final entry in answers.entries) {
      final value = entry.value?.toString().toLowerCase() ?? '';
      if (value.contains('allerg') && (value.contains('drug') || value.contains('supplement'))) {
        // Extract substance allergies from the answer
        final parts = value.split(',');
        for (final part in parts) {
          final trimmed = part.trim();
          if (trimmed.isNotEmpty && !trimmed.contains('no') && !trimmed.contains('none')) {
            allergies.add(trimmed);
          }
        }
      }
    }
    return allergies;
  }
}

class ClientAllergies {
  final String clientId;
  final List<String> foods;
  final List<String> substances;
  final DateTime updatedAt;

  const ClientAllergies({
    required this.clientId,
    required this.foods,
    required this.substances,
    required this.updatedAt,
  });

  factory ClientAllergies.fromMap(Map<String, dynamic> map) {
    return ClientAllergies(
      clientId: map['client_id']?.toString() ?? '',
      foods: (map['foods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      substances: (map['substances'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'client_id': clientId,
      'foods': foods,
      'substances': substances,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool hasFoodAllergy(String food) {
    return foods.any((allergy) => 
        allergy.toLowerCase().contains(food.toLowerCase()) ||
        food.toLowerCase().contains(allergy.toLowerCase()));
  }

  bool hasSubstanceAllergy(String substance) {
    return substances.any((allergy) => 
        allergy.toLowerCase().contains(substance.toLowerCase()) ||
        substance.toLowerCase().contains(allergy.toLowerCase()));
  }
}
