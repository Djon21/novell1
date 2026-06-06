// 50_investigation.ink
// Модуль расследования — поиск улик и взаимодействие с NPC

=== investigation_start ===
Ты решаешься начать расследование.
    -> END

=== find_clue ===
+ [Осмотреться] -> look_around
+ [Поговорить с кем-то] -> talk_to_someone

=== look_around ===
Ты осматриваешься вокруг.
    -> END

=== talk_to_someone ===
Ты подходишь к ближайшему человеку.
    -> END
