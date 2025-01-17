local function tableMerge(result, ...)
    for _, t in ipairs({...}) do
      for _, v in ipairs(t) do
        table.insert(result, v)
      end
    end
end

function sort_inventory(location)
    local inventory = core.get_inventory(location)

    if inventory == nil then
        return
    end

    local main_list = inventory:get_list("main")

    if main_list == nil then
        return
    end

    local inventory_to_sort
    local unsorted_hotbar

    if location.type == "node" then
        inventory_to_sort = main_list
        unsorted_hotbar = { }
    elseif location.type == "player" then
        inventory_to_sort = { unpack(main_list, 10, 36) }
        unsorted_hotbar = { unpack(main_list, 1, 9) }
    else 
        return 
    end

    local merge_stacks = {}

    for _, item in ipairs(inventory_to_sort) do
        if (item:get_name() ~= "") then
            if (merge_stacks[item:get_name()] == nil) then
                merge_stacks[item:get_name()] = item
            else
                merge_stacks[item:get_name()]:set_count(merge_stacks[item:get_name()]:get_count() + item:get_count())
            end
        end
    end

    local merged_inventory = {}
    for _, item in pairs(merge_stacks) do
        table.insert(merged_inventory, item)
    end

    table.sort(merged_inventory, function(a, b)
        return a:get_count() > b:get_count()
    end)

    local sorted_stacked_inventory = {}
    for _, item in ipairs(merged_inventory) do
        if item:get_count() > item:get_stack_max() then
            local count = item:get_count()
            local stacks = math.floor(count / item:get_stack_max())
            for i = 1, stacks do
                local stack = ItemStack(item:get_name())
                stack:set_count(item:get_stack_max())
                stack:set_wear(item:get_wear())
                stack:get_meta():from_table(item:get_meta())
                table.insert(sorted_stacked_inventory, stack)
            end
            local last_stack = ItemStack(item:get_name())
            last_stack:set_count(count % item:get_stack_max())
            last_stack:set_wear(item:get_wear())
            last_stack:get_meta():from_table(item:get_meta())
            table.insert(sorted_stacked_inventory, last_stack)
        else
            table.insert(sorted_stacked_inventory, item)
        end
    end

    local sort_result = {}
    tableMerge(sort_result, unsorted_hotbar, sorted_stacked_inventory)

    inventory:set_list("main", sort_result)

end

core.register_craftitem(
    "mclx_magicwands:inventory_sorting_wand",
    {
        description = "Inventory Sorting Wand",
        inventory_image = "mclx_magicwands_invsort.png",
        stack_max = 1,
        on_use = function(itemstack, user, pointed_thing)
            if pointed_thing.under == nil then
                return
            end
            sort_inventory({ type = "node", pos = pointed_thing.under })
        end,
        on_secondary_use = function(itemstack, user, pointed_thing)
            sort_inventory({ type = "player", name = user:get_player_name() })
        end,
    }
)

core.register_craft({
    output = "mclx_magicwands:inventory_sorting_wand",
    recipe = {
        {"", "mcl_core:iron_ingot", "mcl_core:stick"},
        {"mcl_core:iron_ingot", "mcl_core:stick", "mcl_core:iron_ingot"},
        {"mcl_core:stick", "mcl_core:iron_ingot", ""},
    },
})