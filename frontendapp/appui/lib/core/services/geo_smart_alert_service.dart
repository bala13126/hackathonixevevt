import '../../models/missing_person.dart';

class GeoSmartAlertService {
	double recommendedRadius(UrgencyLevel urgency) {
		switch (urgency) {
			case UrgencyLevel.critical:
				return 10.0;
			case UrgencyLevel.high:
				return 6.0;
			case UrgencyLevel.normal:
				return 3.0;
		}
	}

	double recommendedRadiusForCases(List<MissingPerson> cases) {
		if (cases.isEmpty) return 3.0;
		final topUrgency = cases
				.map((c) => c.urgency)
				.reduce((a, b) => _urgencyWeight(a) >= _urgencyWeight(b) ? a : b);
		return recommendedRadius(topUrgency);
	}

	double priorityScore(MissingPerson person) {
		final urgency = _urgencyWeight(person.urgency);
		final recency = _recencyScore(person.lastSeenTime);
		return (urgency * 0.65) + (recency * 0.35);
	}

	double _urgencyWeight(UrgencyLevel urgency) {
		switch (urgency) {
			case UrgencyLevel.critical:
				return 1.0;
			case UrgencyLevel.high:
				return 0.7;
			case UrgencyLevel.normal:
				return 0.4;
		}
	}

	double _recencyScore(DateTime time) {
		final hours = DateTime.now().difference(time).inHours;
		if (hours <= 0) return 1.0;
		final score = 1.0 - (hours / 72);
		if (score < 0) return 0.0;
		if (score > 1) return 1.0;
		return score;
	}
}
