local ccash = require("ccash.api")
ccash.meta.set_server_address("http://127.0.0.1/")

local module = {}

function module.make_burner()
    while 1 == 1 do
        local name = tostring(math.random(10^2, 10^16 - 1))
        local pass = tostring(math.random(10^8, 10^9 - 1))
        local success, response_code, _ = ccash.register(name, pass)
        if (success == false) then                     
            if response_code ~= 409 then
                return {name = nil, pass = nil}
            end
        else
            return {name = name, pass = pass}
        end
    end
end

local max_log_sz = ccash.properties().max_log -- generated each boot

module.BurnerPool = {}
module.Shell = {}

function module.Shell:new(owner)
    local temp = setmetatable(module.make_burner(), { __index = module.BurnerPool })
    temp.owner = owner

    return temp
end

function module.Shell:deposit(dest)
    ccash.send_funds(self.name, self.pass, dest, ccash.get_bal(self.name))
end

function module.Shell:withdraw()
    ccash.send_funds(self.name, self.pass, self.owner, ccash.get_bal(self.name))
end

function module.Shell:del()
    ccash.delete_self(self.name, self.pass)
end

function module.BurnerPool:new()
    local temp = setmetatable({}, { __index = module.BurnerPool })
    temp.accounts = {}

    return temp
end

function module.BurnerPool:gen_adress()
    local pool_sz = #self.accounts
    local adress

    if (pool_sz == 0) or (self.accounts[pool_sz].capacity == 0) then
        local temp_burner = module.make_burner()
        temp_burner.capacity = max_log_sz - 1
        table.insert(self.accounts, temp_burner)
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

return module
