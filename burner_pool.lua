local ccash = require("ccash.api")

local module = {}

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function make_burner()
    local name = tostring(math.random(10^2, 10^16 - 1))
    local pass = tostring(math.random(10^8, 10^9 - 1))
    local success, _, reason = ccash.register(name, pass)
    return name, pass, success, reason
end

function get_max_log() 
    return ccash.properties().max_log
end

local BurnerPool = {}

function BurnerPool:new() 
    local temp = setmetatable({}, { __index = BurnerPool })
    temp.accounts = {}

    return temp
end

function BurnerPool:generate_adress()
    local pool_sz = #self.accounts
    local adress

    if (pool_sz == 0 or self.accounts[pool_sz].capacity == 0) then
        local name, pass, success, reason = make_burner()
        if (success == false) then return nil end

        table.insert(self.accounts, {name = name, pass = pass, capacity = get_max_log() - 1})
    else
        self.accounts[#self.accounts].capacity = self.accounts[#self.accounts].capacity - 1
        -- print ("capacity decremented to " .. self.accounts[#self.accounts].capacity)
    end

    adress = self.accounts[#self.accounts].name
    table.sort(self.accounts, function(a, b) return (a.capacity < b.capacity) end)

    return adress
end

function BurnerPool:get_logs()
    local log_sum = {}
    for k, v in ipairs(self.accounts) do
        -- print ("we are on account " .. tostring(k))
        local log, _, _ = ccash.get_log_v2(v.name, v.pass)
        if log == nil then return nil end
        v.capacity = #log -- updating capacity for sorting
        local log_sum_sz = #log_sum
        for k2, v2 in ipairs(log) do 
            -- print("log index " .. log_sum_sz + k2)
            log_sum[log_sum_sz + k2] = v2
        end
    end

    return log_sum
end

function BurnerPool:del()
    for k, v in ipairs(self.accounts) do
        ccash.delete_self(v.name, v.pass)
    end
    self.accounts = {}
end

return module
