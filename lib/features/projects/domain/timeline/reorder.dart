/// Where a main-track clip lands when it is dragged to reorder it.
library;

/// The index the clip at [index] moves to (counted after removing it, as
/// `MoveClipCommand` expects) when its center is dragged to timeline time
/// [draggedCenterUs].
///
/// [durationsUs] are the main-track clip lengths in order. The clip goes
/// after every other clip whose center lies before [draggedCenterUs].
int reorderTargetIndex(List<int> durationsUs, int index, int draggedCenterUs) {
  RangeError.checkValidIndex(index, durationsUs);
  var target = 0;
  var start = 0;
  for (var i = 0; i < durationsUs.length; i++) {
    final center = start + durationsUs[i] / 2;
    start += durationsUs[i];
    if (i != index && center < draggedCenterUs) target++;
  }
  return target;
}
