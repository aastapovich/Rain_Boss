## Одно правило попадания капли.
## Капля перебирает массив DropHitConfig по порядку и срабатывает на первом совпадении.
## Совпадение определяется через body.has_method(key_method).
##
## Пример для водяной капли:
##   [ground]  key_method="rain_place",    call_args=["water","_pos_"], do_puddle=true
##   [wheelbarrow]   key_method="rain_wheelbarrow_add", call_args=[1, "water"]
##   [player]  key_method="player_shot",   call_args=[-10, "water"]
class_name DropHitConfig
extends Resource

## Метод-детектор: body.has_method(key_method) → совпадение.
## Он же вызывается на теле: body.callv(key_method, call_args).
@export var key_method: String = ""

## Аргументы для key_method.
## Специальная строка "_pos_" будет заменена на global_position капли в момент удара.
@export var call_args: Array = []

## Опциональный вызов Globals.{globals_method}(globals_args) при совпадении.
## Пример: globals_method="change_gold", globals_args=[1]
@export var globals_method: String = ""
@export var globals_args: Array = []

## Воспроизвести брызги (splash_scene из капли) в точке попадания.
@export var do_splash: bool = true

## Создать лужу (puddle_scene из капли или Puddle.new()) в точке попадания.
@export var do_puddle: bool = false
