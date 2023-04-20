//
// Copyright (c) 2022, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

import ballerina/log;
import ballerinax/postgresql;
import ballerina/sql;
import wso2/apk_common_lib as commons;

public isolated function addApplicationUsagePlanDAO(ApplicationRatePlan atp) returns ApplicationRatePlan|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `INSERT INTO APPLICATION_USAGE_PLAN (NAME, DISPLAY_NAME, 
        ORGANIZATION, DESCRIPTION, QUOTA_TYPE, QUOTA, UNIT_TIME, TIME_UNIT, IS_DEPLOYED, UUID) 
        VALUES (${atp.planName},${atp.displayName},${org},${atp.description},${atp.defaultLimit.'type},
        ${atp.defaultLimit.requestCount?.requestCount},${atp.defaultLimit.requestCount?.unitTime},
        ${atp.defaultLimit.requestCount?.timeUnit},${atp.isDeployed},${atp.planId})`;
        sql:ExecutionResult | sql:Error result =  dbClient->execute(query);
        if result is sql:ExecutionResult {
            return atp;
        } else if result is sql:Error {
            log:printDebug(result.toString());
            return e909402(result);
        }
    }
}

public isolated function getApplicationUsagePlanByIdDAO(string policyId) returns ApplicationRatePlan|commons:APKError|NotFoundError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `SELECT NAME as PLANNAME, DISPLAY_NAME as DISPLAYNAME, DESCRIPTION, 
        UUID as PLANID, IS_DEPLOYED as ISDEPLOYED, 
        QUOTA_TYPE as DefaulLimitType, QUOTA , TIME_UNIT as TIMEUNIT, UNIT_TIME as 
        UNITTIME, QUOTA_UNIT as DATAUNIT FROM APPLICATION_USAGE_PLAN WHERE UUID =${policyId} AND ORGANIZATION =${org}`;
        ApplicationRatePlanDAO | sql:Error result =  dbClient->queryRow(query);
        if result is sql:NoRowsError {
            log:printDebug(result.toString());
            NotFoundError nfe = {body:{code: 90916, message: "Application Usage Plan not found"}};
            return nfe;
        } else if result is ApplicationRatePlanDAO {
            if result.defaulLimitType == "requestCount" {
                ApplicationRatePlan arp = {planName: result.planName, displayName: result.displayName, 
                description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                defaultLimit: {'type: result.defaulLimitType, requestCount: 
                {requestCount: result.quota, timeUnit: result.timeUnit, unitTime: result.unitTime}
                }};
                log:printDebug(arp.toString());
                return arp;
            } else if result.defaulLimitType == "bandwidth" {
                ApplicationRatePlan arp = {planName: result.planName, displayName: result.displayName, 
                description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                defaultLimit: {'type: result.defaulLimitType, bandwidth: 
                {dataAmount: result.quota, dataUnit: <string>result.dataUnit, timeUnit: result.timeUnit, unitTime: result.unitTime}
                }};
                log:printDebug(arp.toString());
                return arp;
            } else {
                ApplicationRatePlan arp = {planName: result.planName, displayName: result.displayName, 
                description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                defaultLimit: {'type: result.defaulLimitType, eventCount: 
                {eventCount:result.quota, timeUnit: result.timeUnit, unitTime: result.unitTime}
                }};
                log:printDebug(arp.toString());
                return arp;
            }
        } else {
            log:printError(result.toString());
            return e909418();
        }
    }
}

public isolated function getApplicationUsagePlansDAO(string org) returns ApplicationRatePlan[]|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        do {
            sql:ParameterizedQuery query = `SELECT NAME as PLANNAME, DISPLAY_NAME as DISPLAYNAME, DESCRIPTION, 
            UUID as PLANID, IS_DEPLOYED as ISDEPLOYED, 
            QUOTA_TYPE as DefaulLimitType, QUOTA , TIME_UNIT as TIMEUNIT, UNIT_TIME as 
            UNITTIME, QUOTA_UNIT as DATAUNIT FROM APPLICATION_USAGE_PLAN WHERE ORGANIZATION =${org}`;
            stream<ApplicationRatePlanDAO, sql:Error?> usagePlanStream = dbClient->query(query);
            ApplicationRatePlanDAO[] usagePlansDAO = check from ApplicationRatePlanDAO usagePlan in usagePlanStream select usagePlan;
            check usagePlanStream.close();
            ApplicationRatePlan[] usagePlans = [];
            if usagePlansDAO is ApplicationRatePlanDAO[]{
                foreach ApplicationRatePlanDAO result in usagePlansDAO {
                    if result.defaulLimitType == "requestCount" {
                        ApplicationRatePlan arp = {planName: result.planName, displayName: result.displayName, 
                        description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                        defaultLimit: {'type: result.defaulLimitType, requestCount: 
                        {requestCount: result.quota, timeUnit: result.timeUnit, unitTime: result.unitTime}
                        }};
                        usagePlans.push(arp);
                    } else if result.defaulLimitType == "bandwidth" {
                        ApplicationRatePlan arp = {planName: result.planName, displayName: result.displayName, 
                        description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                        defaultLimit: {'type: result.defaulLimitType, bandwidth: 
                        {dataAmount: result.quota, dataUnit: <string>result.dataUnit, timeUnit: result.timeUnit, unitTime: result.unitTime}
                        }};
                        usagePlans.push(arp);
                    } else {
                        ApplicationRatePlan arp = {planName: result.planName, displayName: result.displayName, 
                        description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                        defaultLimit: {'type: result.defaulLimitType, eventCount: 
                        {eventCount:result.quota, timeUnit: result.timeUnit, unitTime: result.unitTime}
                        }};
                        usagePlans.push(arp);
                    }
                }
            }
            return usagePlans;
        } on fail var e {
            return e909419(e);
        }
    }
}

public isolated function updateApplicationUsagePlanDAO(ApplicationRatePlan atp) returns ApplicationRatePlan|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `UPDATE APPLICATION_USAGE_PLAN SET DISPLAY_NAME = ${atp.displayName},
         DESCRIPTION = ${atp.description}, QUOTA_TYPE = ${atp.defaultLimit.'type}, QUOTA = ${atp.defaultLimit.requestCount?.requestCount}, 
         UNIT_TIME = ${atp.defaultLimit.requestCount?.unitTime}, TIME_UNIT = ${atp.defaultLimit.requestCount?.timeUnit} 
         WHERE UUID = ${atp.planId} AND ORGANIZATION = ${org}`;
        sql:ExecutionResult | sql:Error result =  dbClient->execute(query);
        if result is sql:ExecutionResult {
            return atp;
        } else {
            log:printDebug(result.toString());
            return e909405(result);
        }
    }
}

public isolated function deleteApplicationUsagePlanDAO(string policyId) returns string|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `DELETE FROM APPLICATION_USAGE_PLAN WHERE UUID = ${policyId} AND ORGANIZATION = ${org}`;
        sql:ExecutionResult | sql:Error result =  dbClient->execute(query);
        if result is sql:ExecutionResult {
            return "deleted";
        } else {
            log:printError(result.toString());
            return e909406(result);
        }
    }
}

public isolated function addBusinessPlanDAO(BusinessPlan stp) returns BusinessPlan|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `INSERT INTO BUSINESS_PLAN (NAME, DISPLAY_NAME, ORGANIZATION, DESCRIPTION, 
        QUOTA_TYPE, QUOTA, UNIT_TIME, TIME_UNIT, IS_DEPLOYED, UUID, 
        RATE_LIMIT_COUNT,RATE_LIMIT_TIME_UNIT,MAX_DEPTH, MAX_COMPLEXITY,
        BILLING_PLAN,CONNECTIONS_COUNT) VALUES (${stp.planName},${stp.displayName},${org},${stp.description},${stp.defaultLimit.'type},
        ${stp.defaultLimit.requestCount?.requestCount},${stp.defaultLimit.requestCount?.unitTime},${stp.defaultLimit.requestCount?.timeUnit},
        ${stp.isDeployed},${stp.planId},${stp.rateLimitCount},${stp.rateLimitTimeUnit},0,
        0,'FREE',0)`;
        sql:ExecutionResult | sql:Error result =  dbClient->execute(query);
        if result is sql:ExecutionResult {
            log:printDebug(result.toString());
            return stp;
        } else { 
            log:printError(result.toString());
            return e909402(result);
        }
    }
}

public isolated function getBusinessPlanByIdDAO(string policyId) returns BusinessPlan|commons:APKError|NotFoundError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `SELECT NAME as PLANNAME, DISPLAY_NAME as DISPLAYNAME, DESCRIPTION, 
        UUID as PLANID, IS_DEPLOYED as ISDEPLOYED, 
        QUOTA_TYPE as DefaulLimitType, QUOTA , TIME_UNIT as TIMEUNIT, UNIT_TIME as 
        UNITTIME, RATE_LIMIT_COUNT as RATELIMITCOUNT, RATE_LIMIT_TIME_UNIT as RATELIMITTIMEUNIT FROM BUSINESS_PLAN WHERE UUID =${policyId} AND ORGANIZATION =${org}`;
        BusinessPlanDAO | sql:Error result =  dbClient->queryRow(query);
        if result is sql:NoRowsError {
            log:printDebug(result.toString());
            NotFoundError nfe = {body:{code: 90916, message: "Business Plan not found"}};
            return nfe;
        } else if result is BusinessPlanDAO {
            if result.defaulLimitType == "requestCount" {
                BusinessPlan bp = {planName: result.planName, displayName: result.displayName, 
                description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                rateLimitCount: result.rateLimitCount, rateLimitTimeUnit: result.rateLimitTimeUnit,
                defaultLimit: {'type: result.defaulLimitType, requestCount: 
                {requestCount: result.quota, timeUnit: result.timeUnit, unitTime: result.unitTime}
                }};
                log:printDebug(bp.toString());
                return bp;
            } else if result.defaulLimitType == "bandwidth" {
                BusinessPlan bp = {planName: result.planName, displayName: result.displayName, 
                description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                rateLimitCount: result.rateLimitCount, rateLimitTimeUnit: result.rateLimitTimeUnit,
                defaultLimit: {'type: result.defaulLimitType, bandwidth: 
                {dataAmount: result.quota, dataUnit: <string>result.dataUnit, timeUnit: result.timeUnit, unitTime: result.unitTime}
                }};
                log:printDebug(bp.toString());
                return bp;
            } else {
                BusinessPlan bp = {planName: result.planName, displayName: result.displayName, 
                description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                rateLimitCount: result.rateLimitCount, rateLimitTimeUnit: result.rateLimitTimeUnit,
                defaultLimit: {'type: result.defaulLimitType, eventCount: 
                {eventCount:result.quota, timeUnit: result.timeUnit, unitTime: result.unitTime}
                }};
                log:printDebug(bp.toString());
                return bp;
            }
        } else {
            log:printError(result.toString());
            return e909420(result);
        }
    }
}

public isolated function getBusinessPlansDAO(string org) returns BusinessPlan[]|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        do {
            sql:ParameterizedQuery query = `SELECT NAME as PLANNAME, DISPLAY_NAME as DISPLAYNAME, DESCRIPTION, 
            UUID as PLANID, IS_DEPLOYED as ISDEPLOYED, 
            QUOTA_TYPE as DefaulLimitType, QUOTA , TIME_UNIT as TIMEUNIT, UNIT_TIME as 
            UNITTIME, RATE_LIMIT_COUNT as RATELIMITCOUNT, RATE_LIMIT_TIME_UNIT as RATELIMITTIMEUNIT FROM BUSINESS_PLAN WHERE ORGANIZATION =${org}`;
            stream<BusinessPlanDAO, sql:Error?> businessPlanStream = dbClient->query(query);
            BusinessPlanDAO[] businessPlansDAO = check from BusinessPlanDAO businessPlan in businessPlanStream select businessPlan;
            check businessPlanStream.close();
            BusinessPlan[] businessPlans =[];
            if businessPlansDAO is BusinessPlanDAO[] {
                foreach BusinessPlanDAO result in businessPlansDAO {
                    if result.defaulLimitType == "requestCount" {
                        BusinessPlan bp = {planName: result.planName, displayName: result.displayName, 
                        description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                        rateLimitCount: result.rateLimitCount, rateLimitTimeUnit: result.rateLimitTimeUnit,
                        defaultLimit: {'type: result.defaulLimitType, requestCount: 
                        {requestCount: result.quota, timeUnit: result.timeUnit, unitTime: result.unitTime}
                        }};
                        businessPlans.push(bp);
                    } else if result.defaulLimitType == "bandwidth" {
                        BusinessPlan bp = {planName: result.planName, displayName: result.displayName, 
                        description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                        rateLimitCount: result.rateLimitCount, rateLimitTimeUnit: result.rateLimitTimeUnit,
                        defaultLimit: {'type: result.defaulLimitType, bandwidth: 
                        {dataAmount: result.quota, dataUnit: <string>result.dataUnit, timeUnit: result.timeUnit, unitTime: result.unitTime}
                        }};
                        businessPlans.push(bp);
                    } else {
                        BusinessPlan bp = {planName: result.planName, displayName: result.displayName, 
                        description: result.description, planId: result.planId, isDeployed: result.isDeployed, 
                        rateLimitCount: result.rateLimitCount, rateLimitTimeUnit: result.rateLimitTimeUnit,
                        defaultLimit: {'type: result.defaulLimitType, eventCount: 
                        {eventCount:result.quota, timeUnit: result.timeUnit, unitTime: result.unitTime}
                        }};
                        businessPlans.push(bp);
                    }
                }
            }
            return businessPlans;
        } on fail var e {
            return e909421(e);
        }
    }
}

public isolated function updateBusinessPlanDAO(BusinessPlan stp) returns BusinessPlan|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `UPDATE BUSINESS_PLAN SET DISPLAY_NAME = ${stp.displayName},
         DESCRIPTION = ${stp.description}, QUOTA_TYPE = ${stp.defaultLimit.'type}, QUOTA = ${stp.defaultLimit.requestCount?.requestCount}, 
         UNIT_TIME = ${stp.defaultLimit.requestCount?.unitTime}, TIME_UNIT = ${stp.defaultLimit.requestCount?.timeUnit},
         RATE_LIMIT_COUNT = ${stp.rateLimitCount} , RATE_LIMIT_TIME_UNIT = ${stp.rateLimitTimeUnit}, CONNECTIONS_COUNT = 0  
         WHERE UUID = ${stp.planId} AND ORGANIZATION = ${org}`;
        sql:ExecutionResult | sql:Error result =  dbClient->execute(query);
        if result is sql:ExecutionResult {
            return stp;
        } else {
            log:printError(result.toString());
            return e909405(result);
        }
    }
}

public isolated function deleteBusinessPlanDAO(string policyId) returns string|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `DELETE FROM BUSINESS_PLAN WHERE UUID = ${policyId} AND ORGANIZATION = ${org}`;
        sql:ExecutionResult | sql:Error result =  dbClient->execute(query);
        if result is sql:ExecutionResult {
            return "";
        } else {
            log:printError(result.toString());
            return e909406(result);
        }
    }
}

public isolated function addDenyPolicyDAO(BlockingCondition bc) returns BlockingCondition|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `INSERT INTO BLOCK_CONDITION (TYPE,BLOCK_CONDITION,ENABLED,ORGANIZATION,UUID) 
        VALUES (${bc.conditionType},${bc.conditionValue},${bc.conditionStatus},${org},${bc.policyId})`;
        sql:ExecutionResult | sql:Error result =  dbClient->execute(query);
        if result is sql:ExecutionResult {
            return bc;
        } else {
            log:printError(result.toString());
            return e909402(result);
        }
    }
}

public isolated function getDenyPolicyByIdDAO(string policyId) returns BlockingCondition|commons:APKError|NotFoundError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `SELECT UUID as POLICYID, TYPE as CONDITIONTYPE, BLOCK_CONDITION as CONDITIONVALUE, ENABLED::BOOLEAN as CONDITIONSTATUS FROM BLOCK_CONDITION WHERE UUID =${policyId} AND ORGANIZATION =${org}`;
        BlockingCondition | sql:Error result =  dbClient->queryRow(query);
        if result is sql:NoRowsError {
            log:printDebug(result.toString());
            NotFoundError nfe = {body:{code: 90916, message: "Deny Policy not found"}};
            return nfe;
        } else if result is BlockingCondition {
            log:printDebug(result.toString());
            return result;
        } else {
            log:printError(result.toString());
            return e909422(result);
        }
    }
}

public isolated function getDenyPoliciesDAO(string org) returns BlockingCondition[]|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        do {
            sql:ParameterizedQuery query = `SELECT UUID as POLICYID, TYPE as CONDITIONTYPE, BLOCK_CONDITION as CONDITIONVALUE, ENABLED::BOOLEAN as CONDITIONSTATUS FROM BLOCK_CONDITION WHERE ORGANIZATION =${org}`;
            stream<BlockingCondition, sql:Error?> denyPoliciesStream = dbClient->query(query);
            BlockingCondition[] denyPolicies = check from BlockingCondition denyPolicy in denyPoliciesStream select denyPolicy;
            check denyPoliciesStream.close();
            return denyPolicies;
        } on fail var e {
            return e909423(e);
        }
    }
}

public isolated function updateDenyPolicyDAO(BlockingConditionStatus status) returns string|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        sql:ParameterizedQuery query = `UPDATE BLOCK_CONDITION SET ENABLED = ${status.conditionStatus} WHERE UUID = ${status.policyId}`;
        sql:ExecutionResult | sql:Error result =  dbClient->execute(query);
        if result is sql:ExecutionResult {
            return "";
        } else { 
            log:printError(result.toString());
            return e909402(result); 
        }
    }
}

public isolated function deleteDenyPolicyDAO(string policyId) returns string|commons:APKError {
    postgresql:Client | error dbClient  = getConnection();
    if dbClient is error {
        return e909401(dbClient);
    } else {
        string org = "carbon.super";
        sql:ParameterizedQuery query = `DELETE FROM BLOCK_CONDITION WHERE UUID = ${policyId} AND ORGANIZATION = ${org}`;
        sql:ExecutionResult | sql:Error result =  dbClient->execute(query);
        if result is sql:ExecutionResult {
            return "";
        } else {
            log:printError(result.toString());
            return e909406(result);
        }
    }
}