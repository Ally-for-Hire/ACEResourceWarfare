if SERVER then
    util.AddNetworkString("BasicMessaging_SendMsg")
    local plyMeta = FindMetaTable("Player")

    function plyMeta:SendMsg(...)
        net.Start("BasicMessaging_SendMsg")
        net.WriteTable({...})
        net.Send(self)
    end

    function BroadcastMsg(...)
        net.Start("BasicMessaging_SendMsg")
        net.WriteTable({...})
        net.Broadcast()
    end
else
    net.Receive("BasicMessaging_SendMsg", function()
        local msg = net.ReadTable()
        for k, v in pairs(msg) do
            if type(v) == "table" and #v == 4 then
                msg[k] = Color(v[1], v[2], v[3], v[4])
            end
        end
        chat.AddText(unpack(msg))
    end)
end