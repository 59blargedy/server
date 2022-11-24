-----------------------------------
-- It's Raining Mannequins!
-----------------------------------
-- Log ID: 4, Quest ID: 29
-- Fyi_Chalmwoh    : !pos -39.273 -16.000 70.126 249
-- Ramona          : !pos 12.511 -7.287 2.939 248
-- Cheupirudaux    : !pos -138.163 11.999 250.949 231
-- mannequin_head  : !additem 1601
-- mannequin_body  : !additem 1602
-- mannequin_hands : !additem 1603
-- mannequin_legs  : !additem 1604
-- mannequin_feet  : !additem 1605
-----------------------------------
require('scripts/globals/items')
require('scripts/globals/keyitems')
require('scripts/globals/npc_util')
require('scripts/globals/quests')
require('scripts/globals/titles')
require('scripts/globals/zone')
require('scripts/globals/interaction/quest')
-----------------------------------
local mhauraID = require('scripts/zones/Mhaura/IDs')
-----------------------------------

local quest = Quest:new(xi.quest.log_id.OTHER_AREAS, xi.quest.id.otherAreas.ITS_RAINING_MANNEQUINS)

quest.sections =
{
    -- Speak to Fyi Chalmwoh at G-8 in Mhaura (in the Goldsmithing shop).
    {
        check = function(player, status, vars)
            return status == QUEST_AVAILABLE
        end,

        [xi.zone.MHAURA] =
        {
            ['Fyi_Chalmwoh'] = quest:progressEvent(305),

            onEventFinish =
            {
                [305] = function(player, csid, option, npc)
                    quest:begin(player)
                end,
            },
        },
    },

    -- Now go to Selbina and talk to Ramona at H-9 in the Weaver's shop. She'll give you Key Item Ye Olde Mannequin Catalogue.
    {
        check = function(player, status, vars)
            return status == QUEST_ACCEPTED and vars.Prog == 0
        end,

        [xi.zone.MHAURA] =
        {
            -- Hint to go to Selbina
            ['Fyi_Chalmwoh'] = quest:event(306),
        },

        [xi.zone.SELBINA] =
        {
            ['Ramona'] = quest:progressEvent(1103),
            -- After this her default cs becomes 175, but we have it down as 170?

            onEventFinish =
            {
                [1103] = function(player, csid, option, npc)
                    npcUtil.giveKeyItem(player, xi.ki.YE_OLDE_MANNEQUIN_CATALOGUE)
                    quest:setVar(player, 'Prog', 1)
                end,
            },
        },
    },

    -- Now go to Northern San d'Oria and talk to Cheupirudaux at F-3 in front of the Woodworking Guild. He'll give you Key Item Mannequin Joint Diagrams.
    {
        check = function(player, status, vars)
            return status == QUEST_ACCEPTED and vars.Prog == 1
        end,

        [xi.zone.MHAURA] =
        {
            -- Hint to go to San d'Oria
            ['Fyi_Chalmwoh'] = quest:event(307),
        },

        [xi.zone.NORTHERN_SAN_DORIA] =
        {
            ['Cheupirudaux'] = quest:progressEvent(759),

            onEventFinish =
            {
                [759] = function(player, csid, option, npc)
                    npcUtil.giveKeyItem(player, xi.ki.MANNEQUIN_JOINT_DIAGRAMS)
                    quest:setVar(player, 'Prog', 2)
                end,
            },
        },
    },

    -- Now go back to Mhaura and trade all 5 pieces to Fyi Chalmwoh.
    {
        check = function(player, status, vars)
            return status == QUEST_ACCEPTED and vars.Prog == 2
        end,

        [xi.zone.MHAURA] =
        {
            ['Fyi_Chalmwoh'] =
            {
                onTrigger = function(player, npc)
                    return quest:event(308)
                end,

                onTrade = function(player, npc, trade)
                    if
                        npcUtil.tradeHasExactly(trade, {
                            xi.items.MANNEQUIN_HEAD,
                            xi.items.MANNEQUIN_BODY,
                            xi.items.MANNEQUIN_HANDS,
                            xi.items.MANNEQUIN_LEGS,
                            xi.items.MANNEQUIN_FEET
                        })
                    then
                        return quest:progressEvent(309)
                    end
                end,
            },

            onEventFinish =
            {
                [309] = function(player, csid, option, npc)
                    player:confirmTrade()

                    quest:setVar(player, 'Prog', 3)
                    quest:setVar(player, 'Wait', os.time())
                end,
            },
        },
    },

    -- You have to wait about one earth minute to get your reward.
    {
        check = function(player, status, vars)
            return status == QUEST_ACCEPTED and vars.Prog == 3
        end,

        [xi.zone.MHAURA] =
        {
            ['Fyi_Chalmwoh'] =
            {
                onTrigger = function(player, npc)
                    local wait = quest:getVar(player, "Wait")
                    if os.time() >= wait + 60 then
                        return quest:progressEvent(311)
                    else
                        return quest:event(310) -- Please wait
                    end
                end,
            },

            onEventFinish =
            {
                [311] = function(player, csid, option, npc)
                    local race = player:getRace()
                    local chosenMannequin = xi.items.HUME_M_MANNEQUIN + race - 1
                    if player:getFreeSlotsCount() > 0 and not player:hasItem(chosenMannequin) then
                        if quest:complete(player) then
                            player:tradeComplete()
                            player:addItem({ id = chosenMannequin, exdata = { [18] = race, [19] = 0 } })
                            player:messageSpecial(mhauraID.text.ITEM_OBTAINED, chosenMannequin)
                        end
                    else
                        player:messageSpecial(mhauraID.text.ITEM_CANNOT_BE_OBTAINED + 4, chosenMannequin)
                    end
                end,
            },
        },
    },
    {
        check = function(player, status, vars)
            return status == xi.quest.status.COMPLETED
        end,

        [xi.zone.MHAURA] =
        {
            ['Fyi_Chalmwoh'] =
            {
                onTrigger = function(player, npc)
                    -- clear out vars
                    player:setLocalVar("alreadyOwned", 0)
                    for i = 1, 8 do
                        if player:hasItem(xi.items.HUME_M_MANNEQUIN + i - 1) then
                            player:setLocalVar("alreadyOwned", utils.setBit(player:getLocalVar("alreadyOwned"), i - 1, 1))
                        end
                    end

                    return quest:event(318, 0, player:getLocalVar("alreadyOwned"), 100000, 2000):replaceDefault()
                end,

                onTrade = function(player, npc, trade)
                    if npcUtil.tradeHasAny(trade, {
                        xi.items.HUME_M_MANNEQUIN,
                        xi.items.HUME_F_MANNEQUIN,
                        xi.items.ELVAAN_M_MANNEQUIN,
                        xi.items.ELVAAN_F_MANNEQUIN,
                        xi.items.TARUTARU_M_MANNEQUIN,
                        xi.items.TARUTARU_F_MANNEQUIN,
                        xi.items.MITHRA_MANNEQUIN,
                        xi.items.GALKA_MANNEQUIN,
                         })
                    then
                        -- clear out var
                        player:setLocalVar("alreadyOwned", 0)
                        for i = 1, 8 do
                            if player:hasItem(xi.items.HUME_M_MANNEQUIN + i - 1) then
                                player:setLocalVar("alreadyOwned", utils.setBit(player:getLocalVar("alreadyOwned"), i - 1, 1))
                            end
                        end

                        return quest:event(319, 2, player:getLocalVar("alreadyOwned"), 100000, 2000)
                    end
                end,
            },
            onEventUpdate = {
                [318] = function(player, csid, option, npc)
                    if player:getGil() >= 100000 then
                        player:updateEvent(1, 1, 0, 2000, option, 1, 0)
                    end
                end,
            },
            onEventFinish =
            {
                [318] = function(player, csid, option, npc)
                    local chosenMannequin = xi.items.HUME_M_MANNEQUIN + option - 1
                    if option > 0 and player:delGil(100000) then
                        player:addItem({ id = chosenMannequin, exdata = { [18] = option, [19] = 0 } })
                        player:messageSpecial(mhauraID.text.ITEM_OBTAINED, chosenMannequin)
                    end
                end,

                [319] = function(player, csid, option, npc)
                    local chosenMannequin = xi.items.HUME_M_MANNEQUIN + option - 1
                    if option > 0 and player:delGil(2000) then
                        player:tradeComplete()
                        player:addItem({ id = chosenMannequin, exdata = { [18] = option, [19] = 0 } })
                        player:messageSpecial(mhauraID.text.ITEM_OBTAINED, chosenMannequin)
                    end
                end,
            },
        },
    },
}

return quest
