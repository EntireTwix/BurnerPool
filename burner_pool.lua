local ccash = require("ccash.api")

local module = {}

function module.make_burner()
    while 1 == 1 do
        local name = tostring(math.random(10^2, 10^16 - 1))
        local pass = tostring(math.random(10^8, 10^9 - 1))
        local success, response_code, _ = ccash.register(name, pass)
        if (success == false) then                     
            if response_code ~= 409 then
                return nil, nil
            end
        else
            return name, pass
        end
    end
end

local max_log_sz = ccash.properties().max_log -- generated each boot

module.BurnerPool = {}

function module.BurnerPool:new() 
    local temp = setmetatable({}, { __index = module.BurnerPool })
    temp.accounts = {}

    return temp
end

function module.BurnerPool:gen_adress()
    local pool_sz = #self.accounts
    local adress

    if (pool_sz == 0) or (self.accounts[pool_sz].capacity == 0) then
        local name, pass = module.make_burner()
        table.insert(self.accounts, {name = name, pass = pass, capacity = max_log_sz - 1})
    else
        self.accounts[#self.accounts].capacity = self.accounts[#self.accounts].capacity - 1
        -- print ("capacity decremented to " .. self.accounts[#self.accounts].capacity)
    end

    adress = self.accounts[#self.accounts].name
    table.sort(self.accounts, function(a, b) return (a.capacity < b.capacity) end)

    return adress
end

function module.BurnerPool:get_logs()
    local log_sum = {}
    for k, v in ipairs(self.accounts) do
        -- print ("we are on account " .. tostring(k))
        local log, _, _ = ccash.get_log_v2(v.name, v.pass)
        if log == nil then return nil end
        v.capacity = max_log_sz - #log -- updating capacity for sorting
        local log_sum_sz = #log_sum
        for k2, v2 in ipairs(log) do 
            -- print("log index " .. log_sum_sz + k2)
            log_sum[log_sum_sz + k2] = v2
        end
    end

    return log_sum
end

function module.BurnerPool:del()
    for k, v in ipairs(self.accounts) do
        ccash.delete_self(v.name, v.pass)
    end
    self.accounts = {}
end

function module.BurnerPool:__gc()
    self:del()
end

return module
