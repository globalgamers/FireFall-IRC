UIHELPER = {};

-- Creates a list box from an array
function UIHELPER.ListboxFromArray(LB_ID, LB_label, LB_array, NiceNames)
	if (NiceNames == true) then
		InterfaceOptions.AddChoiceMenu({id=LB_ID, default=LB_array[1][1],  label=LB_label});
	else
		InterfaceOptions.AddChoiceMenu({id=LB_ID, default=LB_array[1],  label=LB_label});
	end
	
	local NiceLabel;
	local NiceValue;
	
	for i,v in ipairs(LB_array) do
		NiceLabel = v;
		NiceValue = v;
		
		if (NiceNames == true) then
			NiceLabel = v[1];
			NiceValue = v[2];
		end
		
		InterfaceOptions.AddChoiceEntry({menuId=LB_ID, val=NiceValue, label=NiceLabel});
	end
end

-- UI Callbacks
-- Call the given function when the UI option is changed
UIHELPER.UI_Callbacks = {};

-- Register the function
function UIHELPER.AddUICallback(ID, func)
	UIHELPER.UI_Callbacks[ID] = func;
end

-- Check if the function should be called
function UIHELPER.CheckCallbacks(args)
	local func = UIHELPER.UI_Callbacks[args.type];
	if (func) then
		func(args.data);
	end
end