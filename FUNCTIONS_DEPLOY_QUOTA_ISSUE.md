# Firebase Functions Deploy Error – Cause & What To Do

## What went wrong

Deploy failed for **8 functions** with this error (repeated for each):

```text
Quota exceeded for total allowable CPU per project per region.
Container Healthcheck failed.
```

So the failure is **not** a bug in your code. It’s a **Google Cloud quota limit**: in `us-central1` your project has hit the limit for “total allowable CPU per project per region” when creating/updating Cloud Run services (used by 2nd Gen functions).

## Which functions failed

- handleLiveStreamUpdate  
- reconcilePayments  
- sendChatNotification  
- sendFollowerNotification  
- sendLiveStreamNotification  
- sendMessageNotification  
- syncApprovedHosts  
- syncApprovedHostsUpdate  

## Which functions deployed successfully

These **did** deploy, including the one we care about for the viewer list:

- **updateViewerCount** ✅ (viewer list fix is live)
- generateAgoraToken  
- testNotification  
- updateUnfollowCounters  
- migrateApprovedHosts  
- payprimeWebhook  
- initiatePayment  
- verifyPlayStorePurchase  
- sendTeamMessageNotification  
- cleanupInactiveStreams  
- manageStreamState  
- onFollow  
- cleanupOldNotifications  

So the **viewer list / viewer count** change is already deployed and active.

## What you can do

1. **Request a quota increase (recommended)**  
   - Open: [Google Cloud Console → IAM & Admin → Quotas](https://console.cloud.google.com/iam-admin/quotas).  
   - Filter by “Cloud Run” and region “us-central1”.  
   - Find a quota like “Total allowable CPU per project per region” (or similar).  
   - Request an increase.  
   - After it’s approved, run again:  
     `firebase deploy --only functions`  
     (or deploy only the failed functions).

2. **Reduce CPU / number of revisions**  
   - In `functions`, you can lower CPU per function (e.g. in options: `cpu: '1'` → `cpu: '0.5'` or minimum) so total CPU stays under the limit.  
   - Over time, delete old/unused Cloud Run revisions for this project in us-central1 so fewer revisions are active.

3. **Deploy only the failed functions later**  
   Once quota is increased (or after some revisions are pruned), deploy just the 8 that failed, for example:  
   `firebase deploy --only functions:handleLiveStreamUpdate,functions:reconcilePayments,...`  
   (list the 8 function names) so you don’t push all functions again if you don’t need to.

4. **Leave as-is for now**  
   If you don’t need those 8 functions updated immediately, you can leave them on their current versions. The viewer list fix (**updateViewerCount**) is already live.

## Summary

- **Issue:** Quota exceeded for total CPU per project per region (us-central1), not a code error.  
- **Viewer list fix:** Already deployed; **updateViewerCount** is live.  
- **Next step:** Increase Cloud Run CPU quota for the project in us-central1 (or reduce CPU/revisions), then redeploy the 8 failed functions if you need their updates.
