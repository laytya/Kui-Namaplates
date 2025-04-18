
if GetLocale() == "zhTW" then

	if not ParserLibOptimizer then
		ParserLibOptimizer = {
			AURAADDEDOTHERHARMFUL = "受到",
			AURAADDEDOTHERHELPFUL = "獲得了",
			AURAADDEDSELFHARMFUL = "受到了",
			AURAADDEDSELFHELPFUL = "獲得了",
			AURAAPPLICATIONADDEDOTHERHARMFUL = "受到了",
			AURAAPPLICATIONADDEDOTHERHELPFUL = "獲得了",
			AURAAPPLICATIONADDEDSELFHARMFUL = "受到了",
			AURAAPPLICATIONADDEDSELFHELPFUL = "獲得了",
			AURADISPELOTHER = "移除",
			AURADISPELSELF = "移除",
			AURAREMOVEDOTHER = "消失",
			AURAREMOVEDSELF = "消失了",
			COMBATHITCRITOTHEROTHER = "致命一擊",
			COMBATHITCRITOTHERSELF = "致命一擊",
			COMBATHITCRITSELFOTHER = "致命一擊",
			COMBATHITCRITSELFSELF = "致命一擊",
			COMBATHITCRITSCHOOLOTHEROTHER = "致命一擊",
			COMBATHITCRITSCHOOLOTHERSELF = "致命一擊",
			COMBATHITCRITSCHOOLSELFOTHER = "致命一擊",
			COMBATHITCRITSCHOOLSELFSELF = "致命一擊",
			COMBATHITOTHEROTHER = "擊中",
			COMBATHITOTHERSELF = "擊中",
			COMBATHITSELFOTHER = "擊中",
			COMBATHITSELFSELF = "擊中",
			COMBATHITSCHOOLOTHEROTHER = "擊中",
			COMBATHITSCHOOLOTHERSELF = "擊中",
			COMBATHITSCHOOLSELFOTHER = "擊中",
			COMBATHITSCHOOLSELFSELF = "擊中",
			DAMAGESHIELDOTHEROTHER = "反射",
			DAMAGESHIELDOTHERSELF = "反彈",
			DAMAGESHIELDSELFOTHER = "反彈",
			DISPELFAILEDOTHEROTHER = "未能",
			DISPELFAILEDOTHERSELF = "未能",
			DISPELFAILEDSELFOTHER = "未能",
			DISPELFAILEDSELFSELF = "無法",
			HEALEDCRITOTHEROTHER = "發揮極效",
			HEALEDCRITOTHERSELF = "發揮極效",
			HEALEDCRITSELFOTHER = "極效治療",
			HEALEDCRITSELFSELF = "極效治療",
			HEALEDOTHEROTHER = "恢復",
			HEALEDOTHERSELF = "恢復",
			HEALEDSELFOTHER = "治療",
			HEALEDSELFSELF = "治療",
			IMMUNESPELLOTHEROTHER = "免疫",
			IMMUNESPELLSELFOTHER = "免疫",
			IMMUNESPELLOTHERSELF = "免疫",
			IMMUNESPELLSELFSELF = "免疫",
			ITEMENCHANTMENTADDOTHEROTHER = "施放",
			ITEMENCHANTMENTADDOTHERSELF = "施放",
			ITEMENCHANTMENTADDSELFOTHER = "施放",
			ITEMENCHANTMENTADDSELFSELF = "施放",
			MISSEDOTHEROTHER = "沒有擊中",
			MISSEDOTHERSELF = "沒有擊中",
			MISSEDSELFOTHER = "沒有擊中",
			MISSEDSELFSELF = "沒有擊中",
			OPEN_LOCK_OTHER = "使用",
			OPEN_LOCK_SELF = "使用",
			PARTYKILLOTHER = "幹掉",
			PERIODICAURADAMAGEOTHEROTHER = "受到了",
			PERIODICAURADAMAGEOTHERSELF = "受到",
			PERIODICAURADAMAGESELFOTHER = "受到了",
			PERIODICAURADAMAGESELFSELF = "受到",
			PERIODICAURAHEALOTHEROTHER = "獲得",
			PERIODICAURAHEALOTHERSELF = "獲得了",
			PERIODICAURAHEALSELFOTHER = "獲得",
			PERIODICAURAHEALSELFSELF = "獲得了",
			POWERGAINOTHEROTHER = "獲得",
			POWERGAINOTHERSELF = "獲得了",
			POWERGAINSELFSELF = "獲得了",
			POWERGAINSELFOTHER = "獲得",
			PROCRESISTOTHEROTHER = "抵抗了",
			PROCRESISTOTHERSELF = "抵抗了",
			PROCRESISTSELFOTHER = "抵抗了",
			PROCRESISTSELFSELF = "抵抗了",
			SIMPLECASTOTHEROTHER = "施放了",
			SIMPLECASTOTHERSELF = "施放了",
			SIMPLECASTSELFOTHER = "施放了",
			SIMPLECASTSELFSELF = "施放了",
			SIMPLEPERFORMOTHEROTHER = "使用",
			SIMPLEPERFORMOTHERSELF = "使用",
			SIMPLEPERFORMSELFOTHER = "使用",
			SIMPLEPERFORMSELFSELF = "使用",
			SPELLBLOCKEDOTHEROTHER = "格擋",
			SPELLBLOCKEDOTHERSELF = "格擋",
			SPELLBLOCKEDSELFOTHER = "格擋",
			SPELLBLOCKEDSELFSELF = "格擋",
			SPELLCASTOTHERSTART = "開始",
			SPELLCASTSELFSTART = "開始",
			SPELLDEFLECTEDOTHEROTHER = "偏斜",
			SPELLDEFLECTEDOTHERSELF = "偏斜",
			SPELLDEFLECTEDSELFOTHER = "偏斜",
			SPELLDEFLECTEDSELFSELF = "偏斜",
			SPELLDODGEDOTHEROTHER = "閃躲",
			SPELLDODGEDOTHERSELF = "閃躲",
			SPELLDODGEDSELFOTHER = "閃躲",
			SPELLEVADEDOTHEROTHER = "閃避",
			SPELLEVADEDOTHERSELF = "閃避",
			SPELLEVADEDSELFOTHER = "閃避",
			SPELLEVADEDSELFSELF = "閃避",
			SPELLEXTRAATTACKSOTHER = "額外",
			SPELLEXTRAATTACKSOTHER_SINGULAR = "額外",
			SPELLEXTRAATTACKSSELF = "額外",
			SPELLEXTRAATTACKSSELF_SINGULAR = "額外",
			SPELLFAILCASTSELF = "失敗",
			SPELLFAILPERFORMSELF = "失敗",
			SPELLIMMUNEOTHEROTHER = "免疫",
			SPELLIMMUNEOTHERSELF = "免疫",
			SPELLIMMUNESELFOTHER = "免疫",
			SPELLIMMUNESELFSELF = "免疫",
			SPELLINTERRUPTOTHEROTHER = "打斷了",
			SPELLINTERRUPTOTHERSELF = "打斷了",
			SPELLINTERRUPTSELFOTHER = "打斷了",
			SPELLLOGABSORBOTHEROTHER = "吸收了",
			SPELLLOGABSORBOTHERSELF = "吸收了",
			SPELLLOGABSORBSELFOTHER = "吸收了",
			SPELLLOGABSORBSELFSELF = "吸收了",
			SPELLLOGCRITOTHEROTHER = "致命一擊",
			SPELLLOGCRITOTHERSELF = "致命一擊",
			SPELLLOGCRITSCHOOLOTHEROTHER = "致命一擊",
			SPELLLOGCRITSCHOOLOTHERSELF = "致命一擊",
			SPELLLOGCRITSCHOOLSELFOTHER = "致命一擊",
			SPELLLOGCRITSCHOOLSELFSELF = "致命一擊",
			SPELLLOGCRITSELFOTHER = "致命一擊",
			SPELLLOGOTHEROTHER = "擊中",
			SPELLLOGOTHERSELF = "擊中",
			SPELLLOGSCHOOLOTHEROTHER = "擊中",
			SPELLLOGSCHOOLOTHERSELF = "擊中",
			SPELLLOGSCHOOLSELFOTHER = "擊中",
			SPELLLOGSCHOOLSELFSELF = "擊中",
			SPELLLOGSELFOTHER = "擊中",
			SPELLMISSOTHEROTHER = "沒有擊中",
			SPELLMISSOTHERSELF = "沒有擊中",
			SPELLMISSSELFOTHER = "沒有擊中",
			SPELLPARRIEDOTHEROTHER = "招架",
			SPELLPARRIEDOTHERSELF = "招架",
			SPELLPARRIEDSELFOTHER = "招架",
			SPELLPERFORMOTHERSTART = "開始",
			SPELLPERFORMSELFSTART = "開始",
			SPELLPOWERDRAINOTHEROTHER = "吸取",
			SPELLPOWERDRAINOTHERSELF = "吸收",
			SPELLPOWERDRAINSELFOTHER = "吸收",
			SPELLPOWERLEECHOTHEROTHER = "吸取",
			SPELLPOWERLEECHOTHERSELF = "吸取",
			SPELLPOWERLEECHSELFOTHER = "吸取",
			SPELLREFLECTOTHEROTHER = "反彈",
			SPELLREFLECTOTHERSELF = "反彈",
			SPELLREFLECTSELFOTHER = "反彈",
			SPELLREFLECTSELFSELF = "反彈",
			SPELLRESISTOTHEROTHER = "抵抗",
			SPELLRESISTOTHERSELF = "抵抗",
			SPELLRESISTSELFOTHER = "抵抗",
			SPELLRESISTSELFSELF = "抵抗",
			SPELLSPLITDAMAGESELFOTHER = "造成了",
			SPELLSPLITDAMAGEOTHEROTHER = "造成了",
			SPELLSPLITDAMAGEOTHERSELF = "造成了",
			SPELLTERSEPERFORM_OTHER = "使用",
			SPELLTERSEPERFORM_SELF = "使用",
			SPELLTERSE_OTHER = "施放了",
			SPELLTERSE_SELF = "施放了",
			VSABSORBOTHEROTHER = "吸收了",
			VSABSORBOTHERSELF = "吸收了",
			VSABSORBSELFOTHER = "吸收了",
			VSBLOCKOTHEROTHER = "格擋住了",
			VSBLOCKOTHERSELF = "格擋住了",
			VSBLOCKSELFOTHER = "格擋住了",
			VSBLOCKSELFSELF = "格擋住了",
			VSDEFLECTOTHEROTHER = "閃開了",
			VSDEFLECTOTHERSELF = "閃開了",
			VSDEFLECTSELFOTHER = "閃開了",
			VSDEFLECTSELFSELF = "閃開了",
			VSDODGEOTHEROTHER = "閃躲開了",
			VSDODGEOTHERSELF = "閃躲開了",
			VSDODGESELFOTHER = "閃開了",
			VSDODGESELFSELF = "dodge",
			VSENVIRONMENTALDAMAGE_FALLING_OTHER = "高處掉落",
			VSENVIRONMENTALDAMAGE_FALLING_SELF = "火焰",
			VSENVIRONMENTALDAMAGE_FIRE_OTHER = "火焰",
			VSENVIRONMENTALDAMAGE_FIRE_SELF = "火焰",
			VSENVIRONMENTALDAMAGE_LAVA_OTHER = "岩漿",
			VSENVIRONMENTALDAMAGE_LAVA_SELF = "岩漿",
			VSEVADEOTHEROTHER = "閃避",
			VSEVADEOTHERSELF = "閃避",
			VSEVADESELFOTHER = "閃避",
			VSEVADESELFSELF = "閃避",
			VSIMMUNEOTHEROTHER = "免疫",
			VSIMMUNEOTHERSELF = "免疫",
			VSIMMUNESELFOTHER = "免疫",
			VSPARRYOTHEROTHER = "招架",
			VSPARRYOTHERSELF = "招架",
			VSPARRYSELFOTHER = "招架",
			VSRESISTOTHEROTHER = "抵抗",
			VSRESISTOTHERSELF = "抵抗",
			VSRESISTSELFOTHER = "抵抗",
			VSRESISTSELFSELF = "抵抗",
			VSENVIRONMENTALDAMAGE_FATIGUE_OTHER = "精疲力竭",
			VSENVIRONMENTALDAMAGE_SLIME_OTHER = "泥漿",
			VSENVIRONMENTALDAMAGE_SLIME_SELF = "泥漿",
			VSENVIRONMENTALDAMAGE_DROWNING_OTHER = "溺水狀態",
			UNITDIESSELF = "死亡",
			UNITDIESOTHER = "死亡",
			UNITDESTROYEDOTHER = "摧毀",
			
		}

	end

end

