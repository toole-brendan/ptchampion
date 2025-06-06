package grading

// ═════════════════════════════════ PUSH-UPS ═══════════════════════════════════
var pushupScoreMap = map[int]int{
	68: 100, 67: 99, 66: 97, 65: 96, 64: 94, 63: 93, 62: 91, 61: 90,
	60: 88, 59: 87, 58: 85, 57: 84, 56: 82, 55: 81, 54: 79, 53: 78,
	52: 76, 51: 75, 50: 74, 49: 72, 48: 71, 47: 69, 46: 68, 45: 66,
	44: 65, 43: 63, 42: 62, 41: 60, 40: 59, 39: 57, 38: 56, 37: 54,
	36: 53, 35: 51, 34: 50, 33: 48, 32: 47, 31: 46, 30: 44, 29: 43,
	28: 41, 27: 40, 26: 38, 25: 37, 24: 35, 23: 34, 22: 32, 21: 31,
	20: 29, 19: 28, 18: 26, 17: 25, 16: 24, 15: 22, 14: 21, 13: 19,
	12: 18, 11: 16, 10: 15, 9: 13, 8: 12, 7: 10, 6: 9, 5: 7,
	4: 6, 3: 4, 2: 3, 1: 1, 0: 0,
}

// ════════════════════════════════ SIT-UPS ═════════════════════════════════════
var situpScoreMap = map[int]int{
	// 0 – 50 map 1-to-1
	0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9,
	10: 10, 11: 11, 12: 12, 13: 13, 14: 14, 15: 15, 16: 16, 17: 17, 18: 18, 19: 19,
	20: 20, 21: 21, 22: 22, 23: 23, 24: 24, 25: 25, 26: 26, 27: 27, 28: 28, 29: 29,
	30: 30, 31: 31, 32: 32, 33: 33, 34: 34, 35: 35, 36: 36, 37: 37, 38: 38, 39: 39,
	40: 40, 41: 41, 42: 42, 43: 43, 44: 44, 45: 45, 46: 46, 47: 47, 48: 48, 49: 49,
	50: 50,
	// 51 – 78 custom values
	51: 52, 52: 58, 53: 60, 54: 62, 55: 64, 56: 66, 57: 68, 58: 70, 59: 72, 60: 74,
	61: 76, 62: 78, 63: 80, 64: 82, 65: 84, 66: 86, 67: 88, 68: 90, 69: 91, 70: 92,
	71: 93, 72: 94, 73: 95, 74: 96, 75: 97, 76: 98, 77: 99, 78: 100,
}

// ════════════════════════════════ PULL-UPS ════════════════════════════════════
var pullupScoreMap = map[int]int{
	25: 100, 24: 96, 23: 92, 22: 88, 21: 84, 20: 80, 19: 76,
	18: 72, 17: 68, 16: 64, 15: 60, 14: 56, 13: 52, 12: 48,
	11: 44, 10: 40, 9: 36, 8: 32, 7: 28, 6: 24, 5: 20,
	4: 16, 3: 12, 2: 8, 1: 4, 0: 0,
}

// ════════════════════════════════ 2-MILE RUN (sec) ════════════════════════════
var runScoreMap = map[int]int{
	660: 100, 666: 99, 672: 98, 678: 96, 684: 95, 690: 94, 696: 93,
	702: 92, 708: 91, 714: 89, 720: 88, 726: 87, 732: 86, 738: 85,
	744: 84, 750: 82, 756: 81, 762: 80, 768: 79, 774: 78, 780: 76,
	786: 75, 792: 74, 798: 73, 804: 72, 810: 71, 816: 69, 822: 68,
	828: 67, 834: 66, 840: 64, 846: 63, 852: 62, 858: 61, 864: 60,
	870: 59, 876: 57, 882: 56, 888: 55, 894: 54, 900: 53, 906: 51,
	912: 50, 918: 49, 924: 48, 930: 47, 936: 45, 942: 44, 948: 43,
	954: 42, 960: 41, 966: 39, 972: 38, 978: 37, 984: 36, 990: 35,
	996: 33, 1002: 32, 1008: 31, 1014: 30, 1020: 29, 1026: 28, 1032: 27,
	1038: 26, 1044: 24, 1050: 23, 1056: 22, 1062: 21, 1068: 20, 1074: 19,
	1080: 18, 1086: 16, 1092: 15, 1098: 14, 1104: 13, 1110: 12, 1116: 11,
	1122: 10, 1128: 9, 1134: 8, 1140: 6, 1146: 5, 1152: 4, 1158: 3,
	1164: 2, 1170: 0,
}

// ─────────────────────────── helper / public API ─────────────────────────────
func lookup(m map[int]int, key int, higherBetter bool) int {
	if v, ok := m[key]; ok {
		return v
	}
	if higherBetter {
		if key > maxKey(m) {
			return 100
		}
		return 0
	}
	// run (lower is better)
	if key < minKey(m) {
		return 100
	}
	return 0
}
func maxKey(m map[int]int) (mx int) {
	for k := range m {
		if k > mx {
			mx = k
		}
	}
	return
}
func minKey(m map[int]int) (mn int) {
	mn = 1<<31 - 1
	for k := range m {
		if k < mn {
			mn = k
		}
	}
	return
}

// CalculateScore calculates the points (0-100) based on performance
// for a given exercise type.
func CalculateScore(exerciseType string, performanceValue float64) (int, error) {
	v := int(performanceValue)
	switch exerciseType {
	case ExerciseTypePushup:
		return lookup(pushupScoreMap, v, true), nil
	case ExerciseTypeSitup:
		return lookup(situpScoreMap, v, true), nil
	case ExerciseTypePullup:
		return lookup(pullupScoreMap, v, true), nil
	case ExerciseTypeRun:
		return CalculateRunScore(v), nil
	default:
		return 0, ErrUnknownExerciseType
	}
}
